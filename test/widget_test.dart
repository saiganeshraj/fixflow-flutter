import 'package:fixflow/app/providers.dart';
import 'package:fixflow/app/router.dart';
import 'package:fixflow/core/clock.dart';
import 'package:fixflow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('FixFlowRoboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets('Routes render at $width logical pixels', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        originalHandler!(details);
      };
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
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
      expect(find.text('Try the Demo'), findsOneWidget);
      if (const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../docs/screenshots/welcome-${width.toInt()}.png'),
        );
      }
      final router = container.read(routerProvider);
      for (final path in [
        '/catalog',
        '/service/svc-pipe-repair',
        '/book/svc-pipe-repair',
        '/my-bookings',
        '/booking/booking-demo-1',
        '/technician',
        '/about',
        '/missing',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$path at $width');
        if (const bool.fromEnvironment('CAPTURE_SCREENSHOTS') &&
            path == '/catalog') {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../docs/screenshots/catalog-${width.toInt()}.png',
            ),
          );
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -560),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../docs/screenshots/services-${width.toInt()}.png',
            ),
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
