param([switch]$Rebuild)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'd-drive-env.ps1')
Set-Location (Split-Path -Parent $PSScriptRoot)
if ($Rebuild -or -not (Test-Path 'build/web/index.html')) {
    & (Join-Path $PSScriptRoot 'flutter.cmd') build web --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'The web build failed. See the Flutter output above.' }
}
$fixflowPreviewUrl = 'http://127.0.0.1:8080'
$fixflowPreviewResponse = $null
try { $fixflowPreviewResponse = Invoke-WebRequest -UseBasicParsing $fixflowPreviewUrl -TimeoutSec 2 } catch {}
if ($fixflowPreviewResponse -and $fixflowPreviewResponse.Content -notmatch 'FixFlow') {
    throw 'Port 8080 is already used by a different application.'
}
if (-not $fixflowPreviewResponse) {
    $fixflowPreviewServer = Start-Process -WindowStyle Hidden -FilePath (Get-Command node.exe).Source -ArgumentList 'tools/preview.mjs' -WorkingDirectory (Get-Location).Path -RedirectStandardOutput '.local-tools/preview.out.log' -RedirectStandardError '.local-tools/preview.err.log' -PassThru
    for ($fixflowPreviewAttempt = 0; $fixflowPreviewAttempt -lt 20; $fixflowPreviewAttempt++) {
        try { $fixflowPreviewResponse = Invoke-WebRequest -UseBasicParsing $fixflowPreviewUrl -TimeoutSec 1; break } catch { Start-Sleep -Milliseconds 250 }
    }
    if (-not $fixflowPreviewResponse) { throw 'The preview server did not start. See .local-tools/preview.err.log.' }
}
$fixflowPreviewChrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path -LiteralPath $fixflowPreviewChrome)) { throw 'Chrome was not found at its installed location.' }
# The user requests a visible app preview; keep its browser profile on D:.
Start-Process -FilePath $fixflowPreviewChrome -ArgumentList "--user-data-dir=$fixflowTools/preview-chrome", '--no-first-run', '--new-window', $fixflowPreviewUrl
Write-Output "FixFlow is available at $fixflowPreviewUrl"
Write-Output 'After code changes, run: .\tools\preview.cmd -Rebuild'
