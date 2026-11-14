import 'dart:convert';

import 'package:fixflow/core/errors/app_error.dart';
import 'package:fixflow/features/bookings/live_repository.dart';
import 'package:fixflow/features/bookings/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final row = <String, dynamic>{
    'id': 'booking-1',
    'customer_id': 'customer-a',
    'technician_id': 'tech-a',
    'service_id': 'pipe',
    'slot_start_utc': '2026-11-13T04:30:00Z',
    'address_line1': '12 Fictional Road',
    'address_line2': '',
    'city': 'Bengaluru',
    'pincode': '560001',
    'notes': null,
    'price_paise': 149900,
    'status': 'requested',
    'idempotency_key': 'retry-key',
    'created_at': '2026-11-12T02:00:00Z',
    'booking_events': [
      {
        'id': 'event-1',
        'booking_id': 'booking-1',
        'previous_status': null,
        'new_status': 'requested',
        'actor_id': 'customer-a',
        'occurred_at': '2026-11-12T02:00:00Z',
      },
    ],
    'reviews': null,
  };

  test('decodes the unique embedded review as an object', () {
    final reviewedRow = <String, dynamic>{
      ...row,
      'status': 'completed',
      'reviews': {
        'id': 'review-1',
        'booking_id': 'booking-1',
        'customer_id': 'customer-a',
        'rating': 4,
        'comment': 'Good fictional service',
        'created_at': '2026-11-13T06:00:00Z',
      },
    };
    final booking = LiveRepository.decodeBooking(reviewedRow);
    expect(booking.review!.rating, 4);
    expect(booking.review!.bookingId, booking.id);
    expect(booking.review!.createdAt.isUtc, isTrue);
  });

  test(
    'decode live appointment and timeline without local timezone assumptions',
    () {
      final booking = LiveRepository.decodeBooking(row);
      expect(booking.slotStartUtc, DateTime.utc(2026, 11, 13, 4, 30));
      expect(
        booking.slotEndUtc.difference(booking.slotStartUtc),
        const Duration(hours: 1),
      );
      expect(booking.pricePaise, 149900);
      expect(booking.events.single.newStatus, BookingStatus.requested);
      expect(booking.review, isNull);
    },
  );

  test(
    'booking RPC sends inputs and retry key, never trusted price or actor',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'sb_publishable_test',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/rpc/create_booking')) {
            return http.Response(
              jsonEncode('booking-1'),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          return http.Response(
            jsonEncode([row]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = LiveRepository(client);
      addTearDown(repo.dispose);
      final booking = await repo.createBooking(
        BookingRequest(
          serviceId: 'pipe',
          slotStartUtc: DateTime.utc(2026, 11, 13, 4, 30),
          addressLine1: '12 Fictional Road',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'retry-key',
        ),
        'untrusted-client-actor',
      );
      expect(booking.id, 'booking-1');
      final params = jsonDecode(requests.first.body) as Map;
      expect(params['p_idempotency_key'], 'retry-key');
      expect(params.keys, isNot(contains('customer_id')));
      expect(params.keys, isNot(contains('price_paise')));
    },
  );

  test(
    'RLS denial is visible and never reported as successful write',
    () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'sb_publishable_test',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': '42501',
              'message': 'Not your booking',
              'details': null,
              'hint': null,
            }),
            403,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);
      final repo = LiveRepository(client);
      addTearDown(repo.dispose);
      await expectLater(
        repo.acceptBooking('booking-1', 'tech-b'),
        throwsA(isA<UnauthorisedError>()),
      );
    },
  );

  test('availability comes from server RPC', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_test',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/available_slots');
        expect(jsonDecode(request.body), {'p_service_id': 'pipe'});
        return http.Response(
          '[{"slot_start_utc":"2026-11-13T04:30:00+00:00"}]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final repo = LiveRepository(client);
    addTearDown(repo.dispose);
    expect(await repo.fetchAvailableSlots('pipe'), [
      DateTime.utc(2026, 11, 13, 4, 30),
    ]);
  });
}
