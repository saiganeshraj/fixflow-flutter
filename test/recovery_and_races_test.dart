import 'package:fixflow/core/clock.dart';
import 'package:fixflow/core/errors/app_error.dart';
import 'package:fixflow/core/storage.dart';
import 'package:fixflow/demo/demo_repository.dart';
import 'package:fixflow/demo/fixtures.dart';
import 'package:fixflow/features/bookings/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingStorage extends LocalStorage {
  bool fail = false;
  FailingStorage(super.prefs);
  @override
  Future<void> saveBookingsRaw(List<Map<String, dynamic>> bookings) async {
    if (fail) throw const PersistenceError('Simulated disk failure');
    return super.saveBookingsRaw(bookings);
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 12, 2);
  late DemoRepository repo;
  late FailingStorage storage;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'unrelated': 'preserve'});
    prefs = await SharedPreferences.getInstance();
    storage = FailingStorage(prefs);
    repo = DemoRepository(clock: FakeClock(now), storage: storage);
    await repo.initialize();
  });
  tearDown(() => repo.dispose());

  BookingRequest request(
    String key, {
    String service = 'svc-pipe-repair',
    DateTime? slot,
    String pin = '560001',
  }) => BookingRequest(
    serviceId: service,
    slotStartUtc: slot ?? generateSlots(now).first,
    addressLine1: '10 Fictional Street',
    addressLine2: '',
    city: 'Bengaluru',
    pincode: pin,
    idempotencyKey: key,
  );

  test(
    'concurrent duplicate request returns exactly one persisted booking',
    () async {
      final results = await Future.wait(
        List.generate(
          10,
          (_) => repo.createBooking(request('same'), 'customer-priya'),
        ),
      );
      expect(results.map((b) => b.id).toSet(), hasLength(1));
      final saved = await repo.fetchCustomerBookings('customer-priya');
      expect(saved.where((b) => b.idempotencyKey == 'same'), hasLength(1));
    },
  );

  test('cross-service contention reserves the technician once', () async {
    final first = repo.createBooking(request('one'), 'customer-priya');
    final second = repo.createBooking(
      request('two', service: 'svc-drain-unclog'),
      'customer-priya',
    );
    await expectLater(second, throwsA(isA<NoAvailabilityError>()));
    await first;
  });

  test('idempotency keys are scoped by customer', () async {
    final a = await repo.createBooking(request('shared'), 'customer-priya');
    final b = await repo.createBooking(
      request('shared', slot: generateSlots(now)[1]),
      'another-customer',
    );
    expect(a.id, isNot(b.id));
  });

  test(
    'rejects outside horizon, closed hours, fractional hours, invalid pin',
    () async {
      for (final slot in [
        now.add(const Duration(days: 10)),
        DateTime.utc(2026, 11, 13, 12),
        DateTime.utc(2026, 11, 13, 4, 45),
      ]) {
        await expectLater(
          repo.createBooking(request('bad', slot: slot), 'customer-priya'),
          throwsA(isA<ValidationError>()),
        );
      }
      await expectLater(
        repo.createBooking(request('pin', pin: 'abcdef'), 'customer-priya'),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test('failed saves roll back and leave slot available for retry', () async {
    storage.fail = true;
    await expectLater(
      repo.createBooking(request('disk'), 'customer-priya'),
      throwsA(isA<PersistenceError>()),
    );
    expect(
      (await repo.fetchCustomerBookings('customer-priya'))
          .where((b) => b.idempotencyKey == 'disk'),
      isEmpty,
    );
    storage.fail = false;
    final b = await repo.createBooking(request('disk'), 'customer-priya');
    storage.fail = true;
    await expectLater(
      repo.acceptBooking(b.id, b.technicianId),
      throwsA(isA<PersistenceError>()),
    );
    expect((await repo.fetchBooking(b.id))!.status, BookingStatus.requested);
  });

  test(
    'repeat actions do not duplicate events; review adds no status event',
    () async {
      final b = await repo.createBooking(request('life'), 'customer-priya');
      await Future.wait(
        List.generate(5, (_) => repo.acceptBooking(b.id, b.technicianId)),
      );
      expect((await repo.fetchBooking(b.id))!.events, hasLength(2));
      await repo.markEnRoute(b.id, b.technicianId);
      await repo.startService(b.id, b.technicianId);
      await repo.completeService(b.id, b.technicianId);
      await expectLater(
        repo.submitReview(bookingId: b.id, customerId: 'intruder', rating: 5),
        throwsA(isA<UnauthorisedError>()),
      );
      final reviewed = await repo.submitReview(
        bookingId: b.id,
        customerId: 'customer-priya',
        rating: 5,
      );
      expect(reviewed.events, hasLength(5));
      expect(
        repo.availableSlotsForService(b.serviceId, null),
        isNot(contains(b.slotStartUtc)),
      );
    },
  );

  test('cancellation releases reservation', () async {
    final b = await repo.createBooking(request('cancel'), 'customer-priya');
    await repo.cancelBooking(b.id, 'customer-priya');
    expect(
      repo.availableSlotsForService(b.serviceId, null),
      contains(b.slotStartUtc),
    );
  });

  test(
    'corrupt JSON has explicit recovery and reset preserves other keys',
    () async {
      await prefs.setString(kBookingsKey, '[42]');
      final broken = DemoRepository(clock: FakeClock(now), storage: storage);
      addTearDown(broken.dispose);
      await expectLater(broken.initialize(), throwsA(isA<PersistenceError>()));
      await broken.reset();
      await broken.initialize();
      expect(
        await broken.fetchCustomerBookings('customer-priya'),
        hasLength(2),
      );
      expect(prefs.getString('unrelated'), 'preserve');
    },
  );

  test('valid empty persisted workspace is not re-seeded', () async {
    await storage.saveBookingsRaw([]);
    final empty = DemoRepository(clock: FakeClock(now), storage: storage);
    addTearDown(empty.dispose);
    await empty.initialize();
    expect(await empty.fetchCustomerBookings('customer-priya'), isEmpty);
  });

  test('timezone boundary generates UTC slots and relative seed dates', () {
    final boundary = DateTime.utc(2026, 12, 31, 20); // Jan 1 in India
    final slots = generateSlots(boundary);
    expect(slots.first, DateTime.utc(2027, 1, 1, 3, 30));
    expect(slots.every((s) => s.isUtc), isTrue);
    final seeds = DemoFixtures.seedBookings(boundary);
    expect(toServiceTimezone(seeds[0].slotStartUtc).day, 31);
    expect(toServiceTimezone(seeds[1].slotStartUtc).day, 2);
  });
}
