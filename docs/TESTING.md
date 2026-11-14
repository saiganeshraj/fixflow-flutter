# Verification record

GitHub Actions passed for the published code commit `7e46dd9` on 14 November:
[Flutter verification](https://github.com/saiganeshraj/fixflow-flutter/actions/runs/43609710737).
The Linux job runs formatting, analysis, all Flutter tests and the release web
build, then uploads the web artifact. Device and real database checks remain
separate.

14 November design/state update: **51 tests passed**, including three new provider
tests for composed search/category/sort without refetching, asynchronous failures,
and booking-stream/customer-scope changes. The full booking journey and all three
responsive route checks pass. Static analysis reports no issues. The earlier
48-test result below is historical.

Date: 12 November 2026. Host: Windows 11, Flutter 3.47.2 stable, Dart 3.13.2. Do not interpret a fake HTTP response or APK compilation as proof of production security or device operation.

Use `tools/flutter.cmd` / `tools/dart.cmd`, or open `tools/dev-shell.cmd` before other commands. All subsequent local tooling must use D: paths per WORKSPACE.md. Earlier verification used installed C: tooling; Android integration was interrupted while redirecting tools after the user clarified this requirement, then attempted again on D: with the emulator failure recorded below.

## Automated checks

`flutter test --no-pub` passed **48 tests** during continuation:

| File | Behavior |
| --- | --- |
| `test/demo_repository_test.dart` | Original 29 catalog, money, timezone, booking, state machine, review and persistence tests |
| `test/recovery_and_races_test.dart` | Ten regressions: concurrent duplicate requests, cross-service contention, customer-scoped keys, scheduling/pincode validation, disk-failure rollback, repeat actions, review event count, cancellation release, corrupt/empty storage and year-boundary fixtures |
| `test/live_repository_test.dart` | Five tests: UTC and one-to-one review decoding, RPC payload boundary, visible authorization failure and server availability RPC. HTTP is mocked; this does not verify RLS. |
| `test/demo_journey_test.dart` | One full widget journey: catalog → booking, invalid pincode → correction, confirmation → assigned technician stages → customer review |
| `test/widget_test.dart` | Three route/layout checks at 360, 768 and 1440 logical pixels, including unknown routes |

Rendered captures were generated with:

```powershell
flutter test test/widget_test.dart --update-goldens --dart-define=CAPTURE_SCREENSHOTS=true
```

They use deterministic fixtures, bundled text/icon fonts and the Flutter test renderer. Regular CI does not compare cross-platform goldens; it runs the layout checks. Screenshots are in `docs/screenshots`.

The initial counter test referenced a removed `MyApp` and was replaced. Layout tests found and prompted fixes for welcome text, the desktop price summary, the mobile appointment row and inline submission labels. Fake responses now include their originating HTTP request, as required by the installed PostgREST client.

## Build and tooling evidence

* `flutter pub get` succeeded; unused code-generation/font-download dependencies were removed and the app lockfile updated.
* `flutter build web --release --no-pub` succeeded on the final D: build. See PROGRESS.md for the complete check record.
* `flutter build apk --debug --no-pub` succeeded after correcting Windows cross-drive Kotlin caching and excessive Gradle memory settings. Artifact: `build/app/outputs/flutter-apk/app-debug.apk`. This is a development APK.
* `flutter doctor -v` found working Flutter, Android SDK 36.1.0, Java 21 and Chrome tooling. Visual Studio is missing; Windows desktop is outside the target scope.
* Browser automation could not connect to its access host. No interactive release-browser inspection or measured cold-load performance is claimed.
* Pixel_4 (Android 37.1 image) booted, including from a copied D: AVD. The D: integration APK built and installed, but the test connection ended without completing. Emulator crash logs showed repeated Android `DeadSystemException` failures in system processes. The emulator was stopped. Device end-to-end acceptance remains pending on a stable emulator or physical device.

## Run the Android journey

```powershell
flutter emulators --launch Pixel_4
flutter devices
flutter test integration_test/demo_journey_test.dart -d ANDROID_DEVICE_ID
```

The integration entry reuses the UI journey but stores fictional test data in a separate `fixflow_integration.` preferences namespace. It resets only that namespace's three demo keys. The unit/widget entry uses mocked preferences. Both use a deterministic injected clock. Still manually verify process restart, browser refresh, Android back/keyboard behavior, reset confirmation and large text/screen-reader focus.

## Live database checks — pending

The environment has not been supplied with development Supabase configuration, and no database tests were executed. `supabase/tests/access_control.sql` is a real pgTAP script, not a Flutter fake; it checks signup role metadata, grants, scoped reads, wrong actors, invalid transitions, trusted prices, retries and review constraints.

Follow BACKEND.md for `supabase db reset` and `supabase test db` in a disposable local instance and for independent multi-account race tests. Do not claim simultaneous SQL race protection is verified from a single transaction test. No production data was accessed or changed.

## Manual release checklist

Verify in a fresh real browser profile: full workflow, refresh and nested hash-route restore, reset, isolated visitors, unknown IDs, keyboard navigation, text scaling and error recovery. Verify an installed Android build on the named device. Inspect the final published HTTPS URL and links, run GitHub CI on the shared commit and play back the recorded video. These are explicit remaining delivery checks unless PROGRESS.md records their actual results.
