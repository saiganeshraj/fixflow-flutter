. (Join-Path $PSScriptRoot 'd-drive-env.ps1')
$fixflowDartCommand = Join-Path $env:FLUTTER_ROOT 'bin/cache/dart-sdk/bin/dart.exe'
if (-not (Test-Path -LiteralPath $fixflowDartCommand)) {
    throw 'The D: Dart SDK copy is not ready. See docs/WORKSPACE.md.'
}
& $fixflowDartCommand @args
exit $LASTEXITCODE
