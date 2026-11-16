param(
    [string]$DeviceId,
    [int]$Port = 3000,
    [switch]$NoResident
)

$ErrorActionPreference = 'Stop'
$appDirectory = $PSScriptRoot
$properties = Get-Content -LiteralPath (Join-Path $appDirectory 'android/local.properties')
$sdkSetting = $properties | Where-Object { $_ -like 'sdk.dir=*' } | Select-Object -First 1
if (!$sdkSetting) { throw 'Android SDK path is missing from android/local.properties.' }
$sdkDirectory = $sdkSetting.Substring(8).Replace('\\', '\').Replace('\:', ':')
$adb = Join-Path $sdkDirectory 'platform-tools/adb.exe'

Invoke-RestMethod "http://127.0.0.1:$Port/health" -TimeoutSec 5 | Out-Null
if (!$DeviceId) {
    $devices = @(& $adb devices | Select-String '^([^\s]+)\s+device$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Where-Object { $_ -notlike 'emulator-*' })
    if ($devices.Count -ne 1) { throw 'Connect one Android phone with USB debugging, or pass -DeviceId.' }
    $DeviceId = $devices[0]
}

# Route this phone's loopback port to the computer through the USB connection.
& $adb -s $DeviceId reverse "tcp:$Port" "tcp:$Port"
if ($LASTEXITCODE -ne 0) { throw 'Could not connect the phone to the backend through USB.' }
Write-Host "Career Connect phone API: http://127.0.0.1:$Port (USB). Keep the phone connected."
Push-Location $appDirectory
try {
    $flutterArguments = @('run', '--no-pub', '-d', $DeviceId, "--dart-define=API_BASE_URL=http://127.0.0.1:$Port")
    if ($NoResident) { $flutterArguments += '--no-resident' }
    & flutter @flutterArguments
    if ($LASTEXITCODE -ne 0) { throw 'The employee app did not start successfully.' }
} finally {
    Pop-Location
}
