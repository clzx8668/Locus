param(
  [switch]$ShowOnly
)

$flutterRoot = 'D:\flutter'
$androidSdkRoot = 'D:\AndroidSDK'

function Resolve-FlutterBin {
  $preferred = @(
    (Join-Path $flutterRoot 'default\bin\flutter.bat'),
    (Join-Path $flutterRoot 'bin\flutter.bat')
  )

  foreach ($candidate in $preferred) {
    if (Test-Path $candidate) {
      return Split-Path $candidate -Parent
    }
  }

  $discovered = Get-ChildItem -Path $flutterRoot -Directory -ErrorAction SilentlyContinue |
      ForEach-Object {
        $directBin = Join-Path $_.FullName 'bin\flutter.bat'
        $nestedBin = Join-Path $_.FullName 'flutter\bin\flutter.bat'
        if (Test-Path $directBin) {
          return Split-Path $directBin -Parent
        }
        if (Test-Path $nestedBin) {
          return Split-Path $nestedBin -Parent
        }
        return $null
      } |
      Where-Object { $_ } |
      Select-Object -First 1

  return $discovered
}

$flutterBin = Resolve-FlutterBin

if (-not $flutterBin) {
  throw "No flutter.bat found under D:\flutter."
}

if (-not (Test-Path $androidSdkRoot)) {
  throw "Android SDK root not found: $androidSdkRoot"
}

if ($ShowOnly) {
  Write-Output "FLUTTER_BIN=$flutterBin"
  Write-Output "FLUTTER_ROOT=$(Split-Path $flutterBin -Parent)"
  Write-Output "ANDROID_SDK_ROOT=$androidSdkRoot"
  Write-Output "ANDROID_HOME=$androidSdkRoot"
  exit 0
}

$env:FLUTTER_ROOT = Split-Path $flutterBin -Parent
$env:ANDROID_SDK_ROOT = $androidSdkRoot
$env:ANDROID_HOME = $androidSdkRoot

$pathEntries = @(
  $flutterBin,
  (Join-Path $androidSdkRoot 'platform-tools'),
  (Join-Path $androidSdkRoot 'cmdline-tools\latest\bin'),
  (Join-Path $androidSdkRoot 'emulator')
) | Where-Object { Test-Path $_ }

for ($i = $pathEntries.Count - 1; $i -ge 0; $i--) {
  $entry = $pathEntries[$i]
  if (-not $env:PATH.Split(';').Contains($entry)) {
    $env:PATH = "$entry;$env:PATH"
  }
}

Write-Output 'Locus dev environment is now pinned to D drive toolchains.'
Write-Output "FLUTTER_BIN=$flutterBin"
Write-Output "ANDROID_SDK_ROOT=$androidSdkRoot"
