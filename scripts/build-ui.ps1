# Build script: produce a single-file EXE for the ConextLab Demo Installer UI using PyInstaller.
# Run on a Windows machine with Python 3.12 and PyInstaller installed.
# Usage: .\scripts\build-ui.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$uiDir = Join-Path $root 'ui'
$appPy = Join-Path $uiDir 'app.py'

if (!(Test-Path $appPy)) { throw "app.py not found at $appPy" }

# Ensure PyInstaller
$py = 'py -3.12'
Write-Host 'Checking PyInstaller...'
& py -3.12 -m pip show pyinstaller *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'Installing PyInstaller...'
  & py -3.12 -m pip install --upgrade pyinstaller
}

Write-Host 'Building single-file EXE with PyInstaller...'
Push-Location $uiDir
try {
  & py -3.12 -m PyInstaller --noconfirm --onefile --windowed --name ConextLabDemoInstaller `
    --collect-all tkinter `
    app.py
} finally { Pop-Location }

$exe = Join-Path $uiDir 'dist\ConextLabDemoInstaller.exe'
if (Test-Path $exe) {
  Write-Host "Build OK. EXE: $exe"
} else {
  throw 'Build failed - EXE not found.'
}