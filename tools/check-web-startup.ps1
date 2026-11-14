param([string]$Url = 'http://127.0.0.1:8080')
. (Join-Path $PSScriptRoot 'd-drive-env.ps1')
$fixflowCheckRoot = Join-Path $env:TEMP 'web-startup-check'
New-Item -ItemType Directory -Path $fixflowCheckRoot -Force | Out-Null
$fixflowCheckChrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
$fixflowCheckProcess = Start-Process -WindowStyle Hidden -FilePath $fixflowCheckChrome -ArgumentList @(
    '--headless=new', '--no-first-run', '--no-default-browser-check',
    "--user-data-dir=$fixflowCheckRoot/profile", '--enable-logging=stderr',
    '--virtual-time-budget=15000', '--timeout=30000', '--window-size=1440,1000',
    "--screenshot=$fixflowCheckRoot/screenshot.png", '--dump-dom', $Url
) -RedirectStandardOutput (Join-Path $fixflowCheckRoot 'dom.html') -RedirectStandardError (Join-Path $fixflowCheckRoot 'chrome.log') -PassThru
if (-not $fixflowCheckProcess.WaitForExit(45000)) {
    Stop-Process -Id $fixflowCheckProcess.Id
    throw "Chrome startup check timed out. Logs: $fixflowCheckRoot"
}
$fixflowCheckDom = Get-Content (Join-Path $fixflowCheckRoot 'dom.html') -Raw
Get-Content (Join-Path $fixflowCheckRoot 'chrome.log') | Select-Object -Last 10
if ($fixflowCheckDom -notmatch '<flutter-view' -or $fixflowCheckDom -match '<div id="loading"') {
    throw "Flutter did not render its first frame. Diagnostics: $fixflowCheckRoot"
}
Write-Output "Flutter rendered its first frame. Screenshot: $fixflowCheckRoot/screenshot.png"
