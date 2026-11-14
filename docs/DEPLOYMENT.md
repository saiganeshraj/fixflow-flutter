# Release and deployment

On this Windows workspace, use `.\tools\flutter.cmd` in place of `flutter`, and `.\tools\dart.cmd` in place of `dart`. For other commands, open `tools/dev-shell.cmd` first. SDKs, caches and temp files must stay on D:. See WORKSPACE.md. CI runners have their own isolated environment.

## Web

The default bundle is the independent local demo. Flutter/go_router's default hash URL strategy is retained: `/#/catalog`, `/#/booking/ID`. Hash routes survive static-host refresh without server route parsing. Firebase also has an SPA fallback. Do not remove the hash without adding a tested path strategy.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release
node tools/preview.mjs
```

Open `http://127.0.0.1:8080`. Stop preview with Ctrl+C. The Node preview serves existing files only and is intended for localhost. Firebase configuration is `firebase.json`, serving `build/web` with `no-cache` so updated unversioned Flutter entry scripts/assets are revalidated. A startup message remains visible until Flutter's first frame.

To publish, choose a Firebase project in your account, authenticate, and deploy the concrete build after reviewing it:

```powershell
firebase login
firebase deploy --only hosting --project YOUR_FIREBASE_PROJECT_ID
```

No Firebase project has been selected or deployed by this work. Record and inspect the actual HTTPS URL before adding it to README. Test a fresh browser profile, mobile viewport, unknown routes, refresh on a booking hash URL, full lifecycle, persisted review, and reset. Other profiles must retain their own local datasets.

Live is a separate build: `flutter build web --release --dart-define-from-file=config/live.json`. Follow BACKEND.md and verify Auth URL configuration. Keep a separately hosted default demo so backend failure cannot prevent recruiters trying the app. Do not accidentally publish live account configuration as the demo artifact.

## Android

```powershell
flutter doctor -v
flutter devices
flutter build apk --debug
flutter run -d ANDROID_DEVICE_ID
flutter test integration_test/demo_journey_test.dart -d ANDROID_DEVICE_ID
```

Development artifact: `build/app/outputs/flutter-apk/app-debug.apk`, if the build succeeds. A debug APK is not a production-signed release. Exercise booking, persona changes, completion, reviews, process restart/persistence, back navigation and reset on a real device or emulator. Record the actual device and Android version in TESTING.md.

Release signing is wired to an optional ignored `android/key.properties`. It never falls back to the debug key. Before distributing a release, create and securely back up your own upload keystore, then populate that file with `storeFile`, `storePassword`, `keyAlias` and `keyPassword` properties. `storeFile` is an absolute path or a path relative to `android/app`; on Windows use forward slashes in this properties file. Keep passwords out of command history/source and never commit the key. Without these properties no signed release is available. Then run `flutter build apk --release`, verify its signing certificate and install it on your target device. App-store publication and iOS validation are excluded.

GitHub Actions pins Flutter 3.47.2 and runs dependency resolution, formatting, analysis, unit/widget tests and a release web build. The workflow has to run on a published repository before CI can be described as passing. Android/device integration and SQL authorization tests are explicit separate checks in TESTING.md, not part of that Linux web job.
