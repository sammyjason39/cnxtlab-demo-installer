param([string]$ConfigPath = "config/demo-config.json", [switch]$LaunchAfterSetup)

# Self-elevate: Chocolatey and global installs require admin.
if (![bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host 'Requesting elevation (UAC)...'
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-ConfigPath',$ConfigPath)
  if ($LaunchAfterSetup) { $args += '-LaunchAfterSetup' }
  Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $args -Wait
  return
}

. "$PSScriptRoot/lib/Common.ps1"
. "$PSScriptRoot/lib/Detection.ps1"
$log = Initialize-Log 'setup'
$config = Get-DemoConfig $ConfigPath
New-Item -ItemType Directory -Force -Path (Get-InstallRoot $config) | Out-Null
Write-Log "Setup log: $log"

if (!(Test-CommandExists choco)) {
  Write-Log 'Installing Chocolatey'
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  # refresh PATH for this session
  $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}

foreach ($pkg in @('git','gh','nodejs-lts','python312','ollama')) {
  Write-Log "Ensuring Chocolatey package: $pkg"
  Invoke-LoggedCommand "choco install $pkg -y --no-progress --limit-output --exit-when-reboot-detected" -AllowFailure
}

Write-Log 'Ensuring global npm tools'
Invoke-LoggedCommand 'npm install -g n8n openclaw@latest' -AllowFailure

foreach ($model in $config.ollama.models) {
  Write-Log "Pulling Ollama model: $model"
  Invoke-LoggedCommand "ollama pull $model" -AllowFailure
}

$comfyPath = Resolve-DemoPath $config $config.comfyui.path
if (!(Test-Path (Join-Path $comfyPath '.git'))) {
  New-Item -ItemType Directory -Force -Path (Split-Path $comfyPath -Parent) | Out-Null
  Invoke-LoggedCommand "git clone $($config.comfyui.url) `"$comfyPath`""
} else {
  Invoke-LoggedCommand 'git pull' $comfyPath -AllowFailure
}
if (!(Test-Path (Join-Path $comfyPath 'venv'))) { Invoke-LoggedCommand 'py -3.12 -m venv venv' $comfyPath }
Invoke-LoggedCommand "venv\Scripts\python.exe -m pip install --upgrade pip" $comfyPath
Invoke-LoggedCommand "venv\Scripts\python.exe -m pip install --pre torch torchvision torchaudio --index-url $($config.comfyui.torchIndexUrl)" $comfyPath
Invoke-LoggedCommand "venv\Scripts\python.exe -m pip install -r requirements.txt" $comfyPath
Invoke-LoggedCommand "venv\Scripts\python.exe -c `"import torch; print('CUDA available:', torch.cuda.is_available()); raise SystemExit(0 if torch.cuda.is_available() else 1)`"" $comfyPath

foreach ($repo in $config.repositories) {
  $path = Resolve-DemoPath $config $repo.path
  if (!(Test-Path (Join-Path $path '.git'))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $path -Parent) | Out-Null
    Invoke-LoggedCommand "git clone $($repo.url) `"$path`""
  } elseif ($repo.autoPull) {
    Invoke-LoggedCommand 'git pull' $path -AllowFailure
  }
  if ($repo.installCommand) { Invoke-LoggedCommand $repo.installCommand $path }
}

Write-Log 'Final status:'
Test-ComponentStatus $config | Format-Table -AutoSize
Write-Log 'Setup complete'
if ($LaunchAfterSetup) { & "$PSScriptRoot/launch.ps1" -ConfigPath $ConfigPath }