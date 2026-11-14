import 'dart:async';

import 'package:fixflow/app/providers.dart';
import 'package:fixflow/demo/fixtures.dart';
import 'package:fixflow/features/bookings/models.dart';
import 'package:fixflow/features/catalog/catalog_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'search, category and price sort compose without refetching data',
    () async {
      var fetches = 0;
      final container = ProviderContainer(
        overrides: [
          servicesProvider.overrideWith((ref) async {
            fetches++;
            return DemoFixtures.services;
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(servicesProvider.future);
      final controls = container.read(catalogFiltersProvider.notifier);
      controls.selectCategory('cat-plumbing');
      controls.sortBy(ServiceSort.priceLow);
      expect(
        container.read(filteredServicesProvider).requireValue.map((s) => s.id),
        ['svc-drain-unclog', 'svc-pipe-repair'],
      );
      controls.search('  PIPE LEAK  ');
      expect(
        container.read(filteredServicesProvider).requireValue.single.id,
        'svc-pipe-repair',
      );
      controls.selectCategory('cat-electrical');
      expect(container.read(filteredServicesProvider).requireValue, isEmpty);
      controls.reset();
      expect(
        container.read(filteredServicesProvider).requireValue,
        hasLength(6),
      );
      expect(
        container.read(catalogFiltersProvider).sort,
        ServiceSort.recommended,
      );
      expect(fetches, 1);
    },
  );

  test('derived catalog preserves asynchronous loading and failure', () async {
    final result = Completer<List<Service>>();
    final container = ProviderContainer(
      overrides: [servicesProvider.overrideWith((ref) => result.future)],
    );
    addTearDown(container.dispose);
    expect(container.read(filteredServicesProvider).isLoading, isTrue);
    final future = container.read(servicesProvider.future);
    final expectedFailure = expectLater(future, throwsStateError);
    result.completeError(StateError('Catalog unavailable'));
    await expectedFailure;
    expect(container.read(filteredServicesProvider).hasError, isTrue);
  });

  test('booking overview follows stream updates and customer scope', () async {
    final stream = StreamController<List<Booking>>();
    final customer = StateProvider<String>((ref) => 'customer-priya');
    final container = ProviderContainer(
      overrides: [
        bookingCustomerIdProvider.overrideWith((ref) => ref.watch(customer)),
        customerBookingsProvider('customer-priya')
            .overrideWith((ref) => stream.stream),
        customerBookingsProvider('customer-other')
            .overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(stream.close);
    final subscription = container.listen(bookingOverviewProvider, (_, __) {});
    addTearDown(subscription.close);
    final booking = DemoFixtures.seedBookings(DateTime.utc(2026, 11, 14)).first;
    stream.add([booking.copyWith(status: BookingStatus.accepted)]);
    await container.read(customerBookingsProvider('customer-priya').future);
    expect(
      container.read(bookingOverviewProvider).requireValue.upcomingCount,
      1,
    );
    stream.add([booking.copyWith(status: BookingStatus.completed)]);
    await Future<void>.delayed(Duration.zero);
    final completed = container.read(bookingOverviewProvider).requireValue;
    expect(completed.upcomingCount, 0);
    expect(completed.completedCount, 1);
    expect(completed.nextBooking, isNull);
    container.read(customer.notifier).state = 'customer-other';
    await container.read(customerBookingsProvider('customer-other').future);
    expect(
      container.read(bookingOverviewProvider).requireValue.completedCount,
      0,
    );
  });
}
