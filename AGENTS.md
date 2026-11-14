# FixFlow workspace rules

Read `docs/PRODUCT_SPEC.md` and `docs/PROGRESS.md` before continuing.

The user requires all project work, build output, caches, temporary files and emulator data on **D:** because C: is full. The project remains `D:\FlutterProjects\fixflow`.

Use `tools/flutter.cmd` for Flutter; it loads `tools/d-drive-env.ps1` in a child PowerShell process. For other tools load that environment in a per-process script-enabled shell (or use `tools/dev-shell.cmd`). Scripts are disabled by default on this machine, so the launchers pass a process-only execution policy; do not change global policy. Use the copied SDKs under `.local-tools` on D:. Do not fall back to C: caches. Read `docs/WORKSPACE.md`. Existing C: installations may be read; do not delete or move them without explicit authorization. Do not change global environment settings.

Keep the independent demo as the default. Distinguish implemented code from actual platform/database verification. Preserve unrelated work. No sub-agent delegation is required.
