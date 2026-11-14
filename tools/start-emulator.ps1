. (Join-Path $PSScriptRoot 'd-drive-env.ps1')
$fixflowEmulatorCommand = Join-Path $env:ANDROID_HOME 'emulator/emulator.exe'
$fixflowEmulator = Start-Process -WindowStyle Hidden -FilePath $fixflowEmulatorCommand -ArgumentList '-avd Pixel_4 -no-window -no-audio -no-boot-anim -no-snapshot -memory 1536' -RedirectStandardOutput (Join-Path $fixflowRoot 'emulator-d.out.log') -RedirectStandardError (Join-Path $fixflowRoot 'emulator-d.err.log') -PassThru
$fixflowEmulator | Select-Object Id,HasExited
