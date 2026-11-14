import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_error.dart';
import '../catalog/repository.dart';
import 'models.dart';

/// Database RLS scopes reads. RPCs derive the actor and price on the server.
class LiveRepository implements AppRepository {
  final SupabaseClient client;
  final _listeners = <void Function()>[];
  final _changes = StreamController<void>.broadcast(sync: true);
  LiveRepository(this.client);
  void dispose() {
    _listeners.clear();
    _changes.close();
  }

  @override
  void addListener(void Function() listener) => _listeners.add(listener);
  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);
  @override
  Future<void> initialize() async {}

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppError {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const UnauthorisedError();
      if (e.code == '23505') throw const SlotUnavailableError();
      if (e.code == '22023' || e.code == 'P0001') {
        throw ValidationError(e.message);
      }
      throw const PersistenceError(
        'Could not load or save live data. Please refresh and retry.',
      );
    } catch (_) {
      throw const PersistenceError(
        'Could not reach FixFlow. Check your connection and retry.',
      );
    }
  }

  Service _service(Map<String, dynamic> row) => Service(
    id: row['id'],
    categoryId: row['category_id'],
    title: row['title'],
    description: row['description'],
    inclusions: List<String>.from(row['inclusions']),
    pricePaise: row['price_paise'],
    active: row['active'],
  );
  @override
  Future<List<ServiceCategory>> fetchCategories() => _request(
    () async => (await client.from('categories').select().order('name'))
        .map(
          (r) => ServiceCategory(
            id: r['id'],
            name: r['name'],
            iconName: r['icon_name'],
          ),
        )
        .toList(),
  );
  @override
  Future<List<Service>> fetchServices() => _request(
    () async =>
        (await client
                .from('services')
                .select()
                .eq('active', true)
                .order('title'))
            .map(_service)
            .toList(),
  );
  @override
  Future<Service?> fetchService(String id) => _request(() async {
    final row = await client
        .from('services')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _service(row);
  });
  @override
  Future<List<Service>> fetchServicesByCategory(String categoryId) async =>
      (await fetchServices()).where((s) => s.categoryId == categoryId).toList();
  @override
  Future<List<Service>> searchServices(String query) async {
    final q = query.trim().toLowerCase();
    return (await fetchServices())
        .where(
          (s) => '${s.title} ${s.description} ${s.inclusions.join(' ')}'
              .toLowerCase()
              .contains(q),
        )
        .toList();
  }

  @override
  Future<List<DateTime>> fetchAvailableSlots(String serviceId) =>
      _request(() async {
        final rows = await client.rpc(
          'available_slots',
          params: {'p_service_id': serviceId},
        ) as List;
        return rows
            .map((r) => DateTime.parse(r['slot_start_utc']).toUtc())
            .toList();
      });
  @override
  Future<List<Technician>> fetchTechnicians() => _request(() async {
    final rows = await client
        .from('profiles')
        .select('id,display_name,technician_services(service_id)')
        .eq('role', 'technician');
    return rows.map((r) {
      final name = r['display_name'] as String;
      return Technician(
        id: r['id'],
        name: name,
        avatarInitials: name
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join(),
        serviceIds: (r['technician_services'] as List)
            .map((s) => s['service_id'] as String)
            .toList(),
      );
    }).toList();
  });

  static Booking decodeBooking(Map<String, dynamic> r) {
    final start = DateTime.parse(r['slot_start_utc']).toUtc();
    final events =
        (r['booking_events'] as List)
            .map(
              (e) => BookingEvent(
                id: e['id'],
                bookingId: e['booking_id'],
                previousStatus: e['previous_status'] == null
                    ? null
                    : BookingStatus.fromString(e['previous_status']),
                newStatus: BookingStatus.fromString(e['new_status']),
                actorId: e['actor_id'],
                occurredAt: DateTime.parse(e['occurred_at']).toUtc(),
              ),
            )
            .toList()
          ..sort((a, b) {
            final time = a.occurredAt.compareTo(b.occurredAt);
            // Multiple fast RPCs can have the same server timestamp; order by stage.
            return time != 0
                ? time
                : a.newStatus.index.compareTo(b.newStatus.index);
          });
    // booking_id is UNIQUE: PostgREST embeds an object or null here.
    final review = r['reviews'] as Map<String, dynamic>?;
    return Booking(
      id: r['id'],
      customerId: r['customer_id'],
      technicianId: r['technician_id'],
      serviceId: r['service_id'],
      slotStartUtc: start,
      slotEndUtc: start.add(const Duration(hours: 1)),
      addressLine1: r['address_line1'],
      addressLine2: r['address_line2'],
      city: r['city'],
      pincode: r['pincode'],
      notes: r['notes'],
      pricePaise: r['price_paise'],
      status: BookingStatus.fromString(r['status']),
      idempotencyKey: r['idempotency_key'],
      createdAt: DateTime.parse(r['created_at']).toUtc(),
      events: events,
      review: review == null
          ? null
          : Review(
              id: review['id'],
              bookingId: review['booking_id'],
              customerId: review['customer_id'],
              rating: review['rating'],
              comment: review['comment'],
              createdAt: DateTime.parse(review['created_at']).toUtc(),
            ),
    );
  }

  static const _selection = '*,booking_events(*),reviews(*)';
  @override
  Future<List<Booking>> fetchCustomerBookings(String id) => _request(
    () async =>
        (await client
                .from('bookings')
                .select(_selection)
                .eq('customer_id', id)
                .order('created_at', ascending: false))
            .map(decodeBooking)
            .toList(),
  );
  @override
  Future<List<Booking>> fetchTechnicianBookings(String id) => _request(
    () async =>
        (await client
                .from('bookings')
                .select(_selection)
                .eq('technician_id', id)
                .order('slot_start_utc'))
            .map(decodeBooking)
            .toList(),
  );
  @override
  Future<Booking?> fetchBooking(String id) => _request(() async {
    final row = await client
        .from('bookings')
        .select(_selection)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : decodeBooking(row);
  });

  Future<Booking> _mutation(String rpc, Map<String, dynamic> params) =>
      _request(() async {
        final id = await client.rpc(rpc, params: params) as String;
        if (!_changes.isClosed) _changes.add(null);
        for (final listener in List.of(_listeners)) {
          listener();
        }
        final booking = await fetchBooking(id);
        if (booking == null) {
          throw const PersistenceError(
            'Saved, but could not reload the booking. Refresh before retrying.',
          );
        }
        return booking;
      });
  @override
  Future<Booking> createBooking(BookingRequest r, String customerId) =>
      _mutation('create_booking', {
        'p_service_id': r.serviceId,
        'p_slot_start_utc': r.slotStartUtc.toUtc().toIso8601String(),
        'p_address_line1': r.addressLine1,
        'p_address_line2': r.addressLine2,
        'p_city': r.city,
        'p_pincode': r.pincode,
        'p_notes': r.notes,
        'p_idempotency_key': r.idempotencyKey,
      });
  Future<Booking> _transition(String id, String status) =>
      _mutation('transition_booking', {'p_booking_id': id, 'p_status': status});
  @override
  Future<Booking> cancelBooking(String id, String customerId) =>
      _transition(id, 'cancelled');
  @override
  Future<Booking> acceptBooking(String id, String technicianId) =>
      _transition(id, 'accepted');
  @override
  Future<Booking> markEnRoute(String id, String technicianId) =>
      _transition(id, 'en_route');
  @override
  Future<Booking> startService(String id, String technicianId) =>
      _transition(id, 'in_progress');
  @override
  Future<Booking> completeService(String id, String technicianId) =>
      _transition(id, 'completed');
  @override
  Future<Booking> submitReview({
    required String bookingId,
    required String customerId,
    required int rating,
    String? comment,
  }) => _mutation('submit_review', {
    'p_booking_id': bookingId,
    'p_rating': rating,
    'p_comment': comment,
  });

  Stream<List<Booking>> _watch(Future<List<Booking>> Function() load) async* {
    final iterator = StreamIterator(_changes.stream);
    try {
      yield await load();
      while (await iterator.moveNext()) {
        yield await load();
      }
    } finally {
      await iterator.cancel();
    }
  }

  @override
  Stream<List<Booking>> watchCustomerBookings(String id) =>
      _watch(() => fetchCustomerBookings(id));
  @override
  Stream<List<Booking>> watchTechnicianBookings(String id) =>
      _watch(() => fetchTechnicianBookings(id));
}
