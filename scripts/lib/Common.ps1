Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
  Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-DemoConfig {
  param([string]$ConfigPath = "config/demo-config.json")
  $root = Get-ProjectRoot
  $full = if ([System.IO.Path]::IsPathRooted($ConfigPath)) { $ConfigPath } else { Join-Path $root $ConfigPath }
  if (!(Test-Path $full)) { throw "Config not found: $full" }
  Get-Content $full -Raw | ConvertFrom-Json
}

function Resolve-DemoPath {
  param([Parameter(Mandatory)]$Config, [Parameter(Mandatory)][string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  Join-Path $Config.installRoot $Path
}

function Initialize-Log {
  param([string]$Name)
  $root = Get-ProjectRoot
  $dir = Join-Path $root 'logs'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $script:LogPath = Join-Path $dir ("{0}-{1}.log" -f $Name, (Get-Date -Format 'yyyyMMdd-HHmmss'))
  "# $Name $(Get-Date -Format o)" | Out-File -FilePath $script:LogPath -Encoding utf8
  return $script:LogPath
}

function Write-Log {
  param([string]$Message, [string]$Level = 'INFO')
  $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'HH:mm:ss'), $Level, $Message
  Write-Host $line
  if ($script:LogPath) { $line | Out-File -FilePath $script:LogPath -Append -Encoding utf8 }
}

function Test-CommandExists {
  param([string]$Command)
  $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Invoke-LoggedCommand {
  param(
    [Parameter(Mandatory)][string]$Command,
    [string]$WorkingDirectory = (Get-Location).Path,
    [switch]$AllowFailure
  )
  Write-Log "Running: $Command"
  Push-Location $WorkingDirectory
  try {
    cmd.exe /c $Command 2>&1 | Tee-Object -FilePath $script:LogPath -Append
    if ($LASTEXITCODE -ne 0 -and !$AllowFailure) { throw "Command failed ($LASTEXITCODE): $Command" }
  } finally {
    Pop-Location
  }
}

function Start-TerminalCommand {
  param([string]$Title, [string]$Command, [string]$WorkingDirectory)
  $wd = if ($WorkingDirectory) { $WorkingDirectory } else { (Get-Location).Path }
  Write-Log "Starting $Title in ${wd}: $Command"
  Start-Process powershell.exe -ArgumentList @('-NoExit','-Command', "Set-Location '$wd'; `$host.UI.RawUI.WindowTitle='$Title'; $Command") | Out-Null
}

function Wait-HttpReady {
  param([string]$Url, [int]$TimeoutSeconds = 120, [int]$PollIntervalSeconds = 3)
  if ([string]::IsNullOrWhiteSpace($Url)) { return $true }
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  Write-Log "Waiting for readiness: $Url"
  while ((Get-Date) -lt $deadline) {
    try {
      $res = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5
      if ($res.StatusCode -ge 200 -and $res.StatusCode -lt 500) { Write-Log "Ready: $Url"; return $true }
    } catch { Start-Sleep -Seconds $PollIntervalSeconds }
  }
  Write-Log "Timed out waiting for $Url" 'WARN'
  return $false
}

function Open-InChrome {
  param([Parameter(Mandatory)]$Config, [string]$Target)
  if ([string]::IsNullOrWhiteSpace($Target)) { return }
  $chrome = $Config.chromePath
  if (Test-Path $chrome) { Start-Process $chrome $Target } else { Start-Process $Target }
  Write-Log "Opened: $Target"
}
