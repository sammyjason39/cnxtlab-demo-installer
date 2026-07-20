# Build script for the ConextLabDemoInstaller UI
# Run on a Windows machine with .NET 8 SDK installed.
# Usage: .\scripts\build-ui.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$uiDir = Join-Path $root 'installer-ui'

if (!(Test-Path $uiDir)) { throw "installer-ui not found at $uiDir" }

Write-Host 'Restoring and publishing ConextLabDemoInstaller (single-file EXE)...'
Push-Location $uiDir
try {
  dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true /p:IncludeNativeLibrariesForSelfExtract=true
} finally { Pop-Location }

$exe = Join-Path $uiDir 'bin\Release\net8.0-windows\win-x64\publish\ConextLabDemoInstaller.exe'
if (Test-Path $exe) {
  Write-Host "Build OK. EXE: $exe"
} else {
  throw 'Build failed - EXE not found.'
}