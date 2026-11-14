# Dot-source this file in the PowerShell session used for FixFlow commands.
$fixflowRoot = Split-Path -Parent $PSScriptRoot
if ([System.IO.Path]::GetPathRoot($fixflowRoot) -ne 'D:\') {
    throw 'FixFlow tooling must run from the D: workspace.'
}
$fixflowTools = Join-Path $fixflowRoot '.local-tools'
foreach ($folder in @('temp','pub-cache','gradle','android-sdk','android-user','android-avd','appdata','localappdata','java-home','user-profile','npm-cache','npm-global')) {
    New-Item -ItemType Directory -Path (Join-Path $fixflowTools $folder) -Force | Out-Null
}
$env:TEMP = Join-Path $fixflowTools 'temp'
$env:TMP = $env:TEMP
$env:PUB_CACHE = Join-Path $fixflowTools 'pub-cache'
$env:GRADLE_USER_HOME = Join-Path $fixflowTools 'gradle'
$env:ANDROID_HOME = Join-Path $fixflowTools 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $fixflowTools 'android-user'
$env:ANDROID_AVD_HOME = Join-Path $fixflowTools 'android-avd'
$env:ANDROID_EMULATOR_HOME = $env:ANDROID_USER_HOME
$env:APPDATA = Join-Path $fixflowTools 'appdata'
$env:LOCALAPPDATA = Join-Path $fixflowTools 'localappdata'
$env:USERPROFILE = Join-Path $fixflowTools 'user-profile'
$env:npm_config_cache = Join-Path $fixflowTools 'npm-cache'
$env:npm_config_prefix = Join-Path $fixflowTools 'npm-global'
$env:FLUTTER_ROOT = Join-Path $fixflowTools 'flutter'
$env:Path = "$env:FLUTTER_ROOT\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
$fixflowJavaHome = (Join-Path $fixflowTools 'java-home').Replace('\','/')
$fixflowTemp = $env:TEMP.Replace('\','/')
$env:JAVA_TOOL_OPTIONS = "-Duser.home=$fixflowJavaHome -Djava.io.tmpdir=$fixflowTemp"
