# Project-scoped launcher. Never falls back to the C: Flutter installation.
. (Join-Path $PSScriptRoot 'd-drive-env.ps1')
$fixflowFlutterCommand = Join-Path $env:FLUTTER_ROOT 'bin/flutter.bat'
if (-not (Test-Path -LiteralPath $fixflowFlutterCommand)) {
    throw 'The D: Flutter SDK copy is not ready. See docs/WORKSPACE.md.'
}
$fixflowAndroidProperties = Join-Path (Split-Path -Parent $PSScriptRoot) 'android/local.properties'
$fixflowSdkPath = $env:ANDROID_HOME.Replace('\','/')
$fixflowFlutterPath = $env:FLUTTER_ROOT.Replace('\','/')
Set-Content -LiteralPath $fixflowAndroidProperties -Encoding ASCII -Value "sdk.dir=$fixflowSdkPath`nflutter.sdk=$fixflowFlutterPath"
& $fixflowFlutterCommand @args
exit $LASTEXITCODE
