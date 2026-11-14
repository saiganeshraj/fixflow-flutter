import 'package:fixflow/app/providers.dart';
import 'package:fixflow/app/router.dart';
import 'package:fixflow/core/clock.dart';
import 'package:fixflow/core/storage.dart';
import 'package:fixflow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerDemoJourney({bool useRealStorage = false}) {
  testWidgets('Customer books, technician completes, customer reviews', (
    tester,
  ) async {
    if (useRealStorage) {
      SharedPreferences.setPrefix('fixflow_integration.');
    } else {
      SharedPreferences.setMockInitialValues({});
    }
    final prefs = await SharedPreferences.getInstance();
    if (useRealStorage) await LocalStorage(prefs).resetDemoData();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(
          FakeClock(DateTime.utc(2026, 11, 12, 2)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FixFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tapText(String text) async {
      final matches = find.text(text);
      if (matches.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.text(text),
          300,
          maxScrolls: 30,
          scrollable: find.byType(Scrollable).last,
        );
      }
      final target = matches.first;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> openPersonas() async {
      final railControl = find.byTooltip('Switch demo view');
      await tester.tap(
        railControl.evaluate().isNotEmpty ? railControl : find.text('Switch'),
      );
      await tester.pumpAndSettle();
    }

    await tapText('Try the Demo');
    await tapText('Pipe Leak Repair');
    await tapText('Book Now');
    await tapText('9:00 AM');
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.ensureVisible(field('Address Line 1 *'));
    await tester.enterText(field('Address Line 1 *'), '12 Fictional Demo Road');
    await tester.enterText(field('Pincode *'), 'abcdef');
    await tapText('Confirm Booking');
    expect(find.text('Valid 6-digit pincode required'), findsOneWidget);
    await tester.ensureVisible(field('Pincode *'));
    await tester.enterText(field('Pincode *'), '560001');
    await tapText('Confirm Booking');
    expect(find.text('Booking Confirmed'), findsOneWidget);
    final bookings = await container
        .read(repositoryProvider)
        .fetchCustomerBookings('customer-priya');
    final created = bookings.firstWhere(
      (b) => b.addressLine1 == '12 Fictional Demo Road',
    );
    await openPersonas();
    await tapText('Raj Kumar (Technician)');
    final router = container.read(routerProvider);
    router.go('/technician');
    await tester.pumpAndSettle();
    await tapText('Accept Job');
    await tapText('Active');
    await tapText('Mark En Route');
    await tapText('Start Service');
    await tapText('Mark Complete');
    await openPersonas();
    await tapText('Priya Sharma');
    router.go('/booking/${created.id}');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tapText('Submit Review');
    final finished = await container
        .read(repositoryProvider)
        .fetchBooking(created.id);
    expect(finished!.review!.rating, 5);
    expect(finished.events, hasLength(5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
