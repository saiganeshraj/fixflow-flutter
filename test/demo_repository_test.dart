import 'package:flutter_test/flutter_test.dart';
import 'package:fixflow/core/clock.dart';
import 'package:fixflow/core/errors/app_error.dart';
import 'package:fixflow/core/storage.dart';
import 'package:fixflow/demo/demo_repository.dart';
import 'package:fixflow/features/bookings/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sets up an in-memory DemoRepository with a fixed clock.
Future<DemoRepository> _makeRepo(DateTime now) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorage(prefs);
  final clock = FakeClock(now);
  final repo = DemoRepository(clock: clock, storage: storage);
  await repo.initialize();
  return repo;
}

void main() {
  // Fixed test time: 2026-11-12 10:00 UTC (15:30 IST)
  final testNow = DateTime.utc(2026, 11, 12, 10, 0, 0);

  group('Slot generation', () {
    test('generates only future IST slots within 7 days', () async {
      final slots = generateSlots(testNow);
      expect(slots, isNotEmpty);
      for (final slot in slots) {
        expect(
          slot.isAfter(testNow),
          isTrue,
          reason: 'All slots should be in the future',
        );
        final ist = toServiceTimezone(slot);
        expect(ist.hour, greaterThanOrEqualTo(9));
        expect(ist.hour, lessThan(17));
      }
      // No slot should be more than 7 days out from testNow
      final limit = testNow.add(const Duration(days: 7, hours: 1));
      for (final slot in slots) {
        expect(slot.isBefore(limit), isTrue);
      }
    });

    test('no slots generated in the past', () {
      final pastNow = DateTime.utc(2026, 11, 12, 11, 30); // 17:00 IST
      final slots = generateSlots(pastNow);
      for (final slot in slots) {
        expect(slot.isAfter(pastNow), isTrue);
      }
    });
  });

  group('Paise formatting', () {
    test('formats 149900 paise as ₹1,499', () {
      expect(formatPaise(149900), equals('₹1,499'));
    });

    test('formats 99900 paise as ₹999', () {
      expect(formatPaise(99900), equals('₹999'));
    });

    test('formats 199900 paise as ₹1,999', () {
      expect(formatPaise(199900), equals('₹1,999'));
    });

    test('formats 0 paise as ₹0', () {
      expect(formatPaise(0), equals('₹0'));
    });
  });

  group('Timezone conversion', () {
    test('UTC to IST adds 5:30', () {
      final utc = DateTime.utc(2026, 11, 12, 4, 30);
      final ist = toServiceTimezone(utc);
      expect(ist.hour, equals(10));
      expect(ist.minute, equals(0));
    });

    test('IST to UTC subtracts 5:30', () {
      final ist = DateTime(2026, 11, 12, 10, 0);
      final utc = fromServiceTimezone(ist);
      expect(utc.hour, equals(4));
      expect(utc.minute, equals(30));
    });
  });

  group('Booking creation', () {
    test('creates a booking with correct price snapshot', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);
      expect(slots, isNotEmpty);

      final booking = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test Street',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'test-idem-1',
        ),
        'customer-priya',
      );

      expect(booking.pricePaise, equals(149900)); // snapshot from fixture
      expect(booking.status, equals(BookingStatus.requested));
      expect(booking.events.length, equals(1));
      expect(booking.events.first.newStatus, equals(BookingStatus.requested));
    });

    test('idempotent — returns same booking on duplicate key', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final b1 = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test Street',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'test-idem-dup',
        ),
        'customer-priya',
      );

      final b2 = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: 'Different Address',
          addressLine2: '',
          city: 'Mumbai',
          pincode: '400001',
          idempotencyKey: 'test-idem-dup', // same key
        ),
        'customer-priya',
      );

      expect(b1.id, equals(b2.id));
    });

    test('rejects booking for a past slot', () async {
      final repo = await _makeRepo(testNow);
      final pastSlot = testNow.subtract(const Duration(hours: 2));

      expect(
        () => repo.createBooking(
          BookingRequest(
            serviceId: 'svc-pipe-repair',
            slotStartUtc: pastSlot,
            addressLine1: '10 Test Street',
            addressLine2: '',
            city: 'Bengaluru',
            pincode: '560001',
            idempotencyKey: 'test-past',
          ),
          'customer-priya',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects empty address line 1', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      expect(
        () => repo.createBooking(
          BookingRequest(
            serviceId: 'svc-pipe-repair',
            slotStartUtc: slots.first,
            addressLine1: '   ', // whitespace only
            addressLine2: '',
            city: 'Bengaluru',
            pincode: '560001',
            idempotencyKey: 'test-addr',
          ),
          'customer-priya',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('no double-booking same technician slot', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);
      final slot = slots.first;

      // First booking succeeds.
      await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slot,
          addressLine1: '10 Test Street',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'test-slot-1',
        ),
        'customer-priya',
      );

      // Second booking for same slot → different idempotency key,
      // but same service (same eligible technicians) → slot conflict.
      // Since only one technician covers plumbing, this should fail.
      expect(
        () => repo.createBooking(
          BookingRequest(
            serviceId: 'svc-pipe-repair',
            slotStartUtc: slot,
            addressLine1: '20 Another Street',
            addressLine2: '',
            city: 'Bengaluru',
            pincode: '560002',
            idempotencyKey: 'test-slot-2',
          ),
          'customer-priya',
        ),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('Booking state machine', () {
    test(
      'full journey: requested → accepted → en_route → in_progress → completed',
      () async {
        final repo = await _makeRepo(testNow);
        final slots = generateSlots(testNow);

        final booking = await repo.createBooking(
          BookingRequest(
            serviceId: 'svc-pipe-repair',
            slotStartUtc: slots.first,
            addressLine1: '10 Test Street',
            addressLine2: '',
            city: 'Bengaluru',
            pincode: '560001',
            idempotencyKey: 'journey-1',
          ),
          'customer-priya',
        );

        final techId = booking.technicianId; // assigned by repo

        final accepted = await repo.acceptBooking(booking.id, techId);
        expect(accepted.status, equals(BookingStatus.accepted));

        final enRoute = await repo.markEnRoute(booking.id, techId);
        expect(enRoute.status, equals(BookingStatus.enRoute));

        final inProgress = await repo.startService(booking.id, techId);
        expect(inProgress.status, equals(BookingStatus.inProgress));

        final completed = await repo.completeService(booking.id, techId);
        expect(completed.status, equals(BookingStatus.completed));
        expect(completed.events.length, equals(5)); // requested+4 transitions
      },
    );

    test('cannot skip from requested to in_progress', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final booking = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test Street',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'skip-1',
        ),
        'customer-priya',
      );

      expect(
        () => repo.startService(booking.id, booking.technicianId),
        throwsA(isA<InvalidTransitionError>()),
      );
    });

    test('wrong technician cannot act on booking', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final booking = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test Street',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'wrong-tech',
        ),
        'customer-priya',
      );

      expect(
        () => repo.acceptBooking(booking.id, 'tech-meera'), // wrong tech
        throwsA(isA<UnauthorisedError>()),
      );
    });

    test('customer can cancel requested booking', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final booking = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test Street',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'cancel-1',
        ),
        'customer-priya',
      );

      final cancelled = await repo.cancelBooking(booking.id, 'customer-priya');
      expect(cancelled.status, equals(BookingStatus.cancelled));
    });

    test('cannot cancel after en_route', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final booking = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test Street',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'cancel-enroute',
        ),
        'customer-priya',
      );

      await repo.acceptBooking(booking.id, booking.technicianId);
      await repo.markEnRoute(booking.id, booking.technicianId);

      expect(
        () => repo.cancelBooking(booking.id, 'customer-priya'),
        throwsA(isA<InvalidTransitionError>()),
      );
    });

    test('completed booking is terminal — cannot cancel', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final b = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'terminal-1',
        ),
        'customer-priya',
      );
      await repo.acceptBooking(b.id, b.technicianId);
      await repo.markEnRoute(b.id, b.technicianId);
      await repo.startService(b.id, b.technicianId);
      await repo.completeService(b.id, b.technicianId);

      expect(
        () => repo.cancelBooking(b.id, 'customer-priya'),
        throwsA(isA<InvalidTransitionError>()),
      );
    });
  });

  group('Reviews', () {
    test('customer can review completed booking once', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final b = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'review-1',
        ),
        'customer-priya',
      );
      await repo.acceptBooking(b.id, b.technicianId);
      await repo.markEnRoute(b.id, b.technicianId);
      await repo.startService(b.id, b.technicianId);
      await repo.completeService(b.id, b.technicianId);

      final reviewed = await repo.submitReview(
        bookingId: b.id,
        customerId: 'customer-priya',
        rating: 5,
        comment: 'Excellent service!',
      );

      expect(reviewed.review, isNotNull);
      expect(reviewed.review!.rating, equals(5));
      expect(reviewed.review!.comment, equals('Excellent service!'));
    });

    test('cannot review same booking twice', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final b = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'review-dup',
        ),
        'customer-priya',
      );
      await repo.acceptBooking(b.id, b.technicianId);
      await repo.markEnRoute(b.id, b.technicianId);
      await repo.startService(b.id, b.technicianId);
      await repo.completeService(b.id, b.technicianId);

      await repo.submitReview(
        bookingId: b.id,
        customerId: 'customer-priya',
        rating: 4,
      );

      expect(
        () => repo.submitReview(
          bookingId: b.id,
          customerId: 'customer-priya',
          rating: 3,
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('cannot review active booking', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final b = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'review-active',
        ),
        'customer-priya',
      );

      expect(
        () => repo.submitReview(
          bookingId: b.id,
          customerId: 'customer-priya',
          rating: 5,
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('review rating must be 1–5', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      final b = await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'review-rating',
        ),
        'customer-priya',
      );
      await repo.acceptBooking(b.id, b.technicianId);
      await repo.markEnRoute(b.id, b.technicianId);
      await repo.startService(b.id, b.technicianId);
      await repo.completeService(b.id, b.technicianId);

      expect(
        () => repo.submitReview(
          bookingId: b.id,
          customerId: 'customer-priya',
          rating: 0,
        ),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  group('Persistence', () {
    test('bookings survive re-initialization', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      final clock = FakeClock(testNow);

      final repo1 = DemoRepository(clock: clock, storage: storage);
      await repo1.initialize();
      final slots = generateSlots(testNow);

      final b = await repo1.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'persist-1',
        ),
        'customer-priya',
      );

      // Create a second repo with the same storage.
      final repo2 = DemoRepository(clock: clock, storage: storage);
      await repo2.initialize();

      final found = await repo2.fetchBooking(b.id);
      expect(found, isNotNull);
      expect(found!.id, equals(b.id));
    });

    test('reset clears all bookings and re-seeds', () async {
      final repo = await _makeRepo(testNow);
      final slots = generateSlots(testNow);

      await repo.createBooking(
        BookingRequest(
          serviceId: 'svc-pipe-repair',
          slotStartUtc: slots.first,
          addressLine1: '10 Test',
          addressLine2: '',
          city: 'Bengaluru',
          pincode: '560001',
          idempotencyKey: 'reset-1',
        ),
        'customer-priya',
      );

      await repo.reset();

      // After reset, 'reset-1' booking should not exist.
      final customerBookings = await repo.fetchCustomerBookings(
        'customer-priya',
      );
      final ids = customerBookings.map((b) => b.idempotencyKey).toList();
      expect(ids.contains('reset-1'), isFalse);
      // Seed data should be present.
      expect(ids, contains('idem-demo-1'));
    });
  });

  group('Catalog', () {
    test('fetches 3 categories', () async {
      final repo = await _makeRepo(testNow);
      final cats = await repo.fetchCategories();
      expect(cats.length, equals(3));
    });

    test('fetches 6 services', () async {
      final repo = await _makeRepo(testNow);
      final svcs = await repo.fetchServices();
      expect(svcs.length, equals(6));
    });

    test('search returns matching services', () async {
      final repo = await _makeRepo(testNow);
      final results = await repo.searchServices('plumb');
      expect(results, isNotEmpty);
      for (final s in results) {
        expect(
          s.title.toLowerCase().contains('plumb') ||
              s.description.toLowerCase().contains('plumb'),
          isTrue,
        );
      }
    });

    test('empty search returns all services', () async {
      final repo = await _makeRepo(testNow);
      final all = await repo.fetchServices();
      final searched = await repo.searchServices('');
      expect(searched.length, equals(all.length));
    });
  });
}
