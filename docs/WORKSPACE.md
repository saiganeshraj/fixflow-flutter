# D: drive requirement

User requirement, confirmed during continuation: keep this project, build output, tool caches, emulator data and temporary work on **D:** because C: is full.

Project root: `D:\FlutterProjects\fixflow`. Do not relocate it to C:. Do not use default C: Pub, Gradle, Android AVD or temporary directories for further work. Existing installed SDKs may be read from C:, but any tool that mutates its own SDK cache must be run from a D: copy. Keep per-project tools and caches in ignored `.local-tools` on D:.

If Chrome debug startup hangs at “Waiting for connection from debug service”,
use `.\tools\preview.cmd` for the verified release preview at
`http://127.0.0.1:8080`. Run `.\tools\preview.cmd -Rebuild` after code changes.
The preview browser profile stays under `.local-tools/preview-chrome` on D:.

Use `tools/d-drive-env.ps1` before tool commands once SDK copies are prepared. It changes only the current PowerShell process environment, not global user settings. Do not delete the user's C: SDKs/caches to reclaim space without explicit permission.

Prefer `.\tools\flutter.cmd <arguments>` for Flutter: it loads the environment, explicitly invokes the D: SDK and updates ignored Android local SDK paths. For Dart, Android, Node or Firebase commands, first run `. .\tools\d-drive-env.ps1` in that terminal. `USERPROFILE`, app-data directories, Java home data, temp, Pub, Gradle, npm and Android paths are redirected only in that tool process; your Windows account/profile settings are unchanged. Java binaries may still be read from the installed Java binaries on C:, with its user data and temporary files redirected to D:.

SDKs and reusable caches are **copied**, not moved or removed. Existing C: data remains untouched. The launcher must never silently fall back to a C: SDK if a D: copy is incomplete. Use `-no-snapshot` when starting the copied emulator to avoid restoring old snapshot paths.

PowerShell scripts are disabled by default on this machine. Use `tools/flutter.cmd` for Flutter, or `tools/dev-shell.cmd` for an interactive terminal with the D: environment. These wrappers enable locally authored scripts only in their child process using `-ExecutionPolicy Bypass`; they do not change the system/user execution policy. Direct `.ps1` calls in the default terminal will fail until a process-scoped policy is selected.

Use `tools/dart.cmd` for Dart commands. Local VS Code workspace settings also select the D: SDK and process environment; they are ignored in Git because they describe this machine. SDK/environment settings follow the [official Dart Code settings reference](https://dartcode.org/docs/settings/).

Earlier verification used the preinstalled C: SDKs and their default caches. That was identified and stopped when this requirement was clarified. Subsequent commands must follow this record. The Android integration test was interrupted during this change; do not claim it passed.

## Migration evidence

The existing Flutter SDK, Android SDK, Pub cache, Gradle distribution/modules and Pixel_4 AVD were copied into `.local-tools` on D:. Snapshot data was excluded from the AVD copy. The copied AVD `.ini` paths were rewritten to D:. Flutter 3.47.2 / Dart 3.13.2 run from the copied SDK. `pub get --offline` regenerated the app package configuration with D: dependency roots, and ignored `android/local.properties` now selects D: Flutter/Android SDKs. Final D: validation results are recorded in PROGRESS.md.

An initial sandbox network restriction blocked the copied SDK's first-run package advisory metadata request. The required first-run setup was retried with network access while keeping all SDK/cache/temp locations on D:.

The subsequent D: Android integration attempt built and installed but did not complete because Android system processes crashed. The normal development APK was then rebuilt on D:. Device acceptance remains pending; see PROGRESS.md.
