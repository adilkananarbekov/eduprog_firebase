param(
  [ValidateSet('usb', 'wifi')]
  [string]$Connection = 'usb',
  [string]$DeviceId,
  [string]$HostIp,
  [int]$Port = 8080,
  [switch]$PrintOnly,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'

function Resolve-AdbPath {
  $command = Get-Command adb -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $sdkAdb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
  if (Test-Path $sdkAdb) {
    return $sdkAdb
  }

  throw 'adb was not found. Install Android platform-tools or add adb to PATH.'
}

function Resolve-DeviceId {
  param(
    [string]$AdbPath,
    [string]$ExplicitDeviceId
  )

  if ($ExplicitDeviceId) {
    return $ExplicitDeviceId
  }

  $deviceLines = @(
    & $AdbPath devices |
      Select-Object -Skip 1 |
      Where-Object { $_ -match '\S' } |
      ForEach-Object {
        $parts = $_ -split '\s+'
        if ($parts.Length -ge 2 -and $parts[1] -eq 'device') {
          $parts[0]
        }
      }
  )

  if (-not $deviceLines) {
    throw 'No Android devices were found by adb.'
  }

  if ($deviceLines.Count -gt 1) {
    throw "Multiple Android devices were found. Pass -DeviceId. Devices: $($deviceLines -join ', ')"
  }

  return $deviceLines[0]
}

function Resolve-LanIp {
  $config = Get-NetIPConfiguration |
    Where-Object { $_.IPv4DefaultGateway -and $_.IPv4Address } |
    Select-Object -First 1

  if (-not $config) {
    throw 'Could not determine a LAN IPv4 address automatically. Pass -HostIp.'
  }

  return $config.IPv4Address.IPAddress
}

$adbPath = Resolve-AdbPath
$resolvedDeviceId = Resolve-DeviceId -AdbPath $adbPath -ExplicitDeviceId $DeviceId

if ($Connection -eq 'usb') {
  if (-not $PrintOnly) {
    & $adbPath -s $resolvedDeviceId reverse "tcp:$Port" "tcp:$Port" | Out-Null
  }
  $baseUrl = "http://127.0.0.1:$Port"
}
else {
  $resolvedHostIp = if ($HostIp) { $HostIp } else { Resolve-LanIp }
  $baseUrl = "http://${resolvedHostIp}:$Port"
}

$commandArgs = @(
  'run'
  '-d'
  $resolvedDeviceId
  "--dart-define=EDUOPS_BASE_URL=$baseUrl"
) + $FlutterArgs

Write-Host "Device: $resolvedDeviceId"
Write-Host "Connection: $Connection"
Write-Host "Backend: $baseUrl"
Write-Host "Command: flutter $($commandArgs -join ' ')"

if (-not $PrintOnly) {
  & flutter @commandArgs
}
