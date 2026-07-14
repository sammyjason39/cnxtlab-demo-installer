param([string]$ConfigPath = "config/demo-config.json")
. "$PSScriptRoot/lib/Common.ps1"
$log = Initialize-Log 'launch'
$config = Get-DemoConfig $ConfigPath
Write-Log "Launch log: $log"

foreach ($svc in $config.services) {
  $name = $svc.name
  $cmd = if ($svc.commandFrom -eq 'comfyui.launchCommand') { $config.comfyui.launchCommand } else { $svc.command }
  $wd = if ($svc.workingDirectoryFrom -eq 'comfyui.path') { Resolve-DemoPath $config $config.comfyui.path } else { $config.installRoot }
  $ready = if ($svc.readinessUrlFrom -eq 'comfyui.readinessUrl') { $config.comfyui.readinessUrl } else { $svc.readinessUrl }
  $open = if ($svc.urlToOpenFrom -eq 'comfyui.urlToOpen') { $config.comfyui.urlToOpen } else { $svc.urlToOpen }
  Start-TerminalCommand $name $cmd $wd
  if ($ready) { Wait-HttpReady $ready $config.readiness.timeoutSeconds $config.readiness.pollIntervalSeconds | Out-Null }
  if ($open) { Open-InChrome $config $open }
}

foreach ($repo in $config.repositories) {
  $path = Resolve-DemoPath $config $repo.path
  if ($repo.launchCommand) {
    Start-TerminalCommand $repo.name $repo.launchCommand $path
    if ($repo.readinessUrl) { Wait-HttpReady $repo.readinessUrl $config.readiness.timeoutSeconds $config.readiness.pollIntervalSeconds | Out-Null }
    if ($repo.urlToOpen) { Open-InChrome $config $repo.urlToOpen }
  } elseif ($repo.fileToOpen) {
    Open-InChrome $config (Join-Path $path $repo.fileToOpen)
  }
}
Write-Log 'Launch sequence complete'
