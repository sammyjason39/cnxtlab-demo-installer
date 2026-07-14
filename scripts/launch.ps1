param([string]$ConfigPath = "config/demo-config.json")
. "$PSScriptRoot/lib/Common.ps1"
$log = Initialize-Log 'launch'
$config = Get-DemoConfig $ConfigPath
Write-Log "Launch log: $log"

function Get-OptionalProperty {
  param([Parameter(Mandatory)]$Object, [Parameter(Mandatory)][string]$Name)
  if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
  return $null
}

foreach ($svc in $config.services) {
  $name = $svc.name
  $commandFrom = Get-OptionalProperty $svc 'commandFrom'
  $workingDirectoryFrom = Get-OptionalProperty $svc 'workingDirectoryFrom'
  $readinessUrlFrom = Get-OptionalProperty $svc 'readinessUrlFrom'
  $urlToOpenFrom = Get-OptionalProperty $svc 'urlToOpenFrom'

  $cmd = if ($commandFrom -eq 'comfyui.launchCommand') { $config.comfyui.launchCommand } else { Get-OptionalProperty $svc 'command' }
  $wd = if ($workingDirectoryFrom -eq 'comfyui.path') { Resolve-DemoPath $config $config.comfyui.path } else { Get-InstallRoot $config }
  $ready = if ($readinessUrlFrom -eq 'comfyui.readinessUrl') { $config.comfyui.readinessUrl } else { Get-OptionalProperty $svc 'readinessUrl' }
  $open = if ($urlToOpenFrom -eq 'comfyui.urlToOpen') { $config.comfyui.urlToOpen } else { Get-OptionalProperty $svc 'urlToOpen' }

  if ($cmd) { Start-TerminalCommand $name $cmd $wd }
  if ($ready) { Wait-HttpReady $ready $config.readiness.timeoutSeconds $config.readiness.pollIntervalSeconds | Out-Null }
  if ($open) { Open-InChrome $config $open }
}

foreach ($repo in $config.repositories) {
  $path = Resolve-DemoPath $config $repo.path
  $launchCommand = Get-OptionalProperty $repo 'launchCommand'
  $readinessUrl = Get-OptionalProperty $repo 'readinessUrl'
  $urlToOpen = Get-OptionalProperty $repo 'urlToOpen'
  $fileToOpen = Get-OptionalProperty $repo 'fileToOpen'

  if ($launchCommand) {
    Start-TerminalCommand $repo.name $launchCommand $path
    if ($readinessUrl) { Wait-HttpReady $readinessUrl $config.readiness.timeoutSeconds $config.readiness.pollIntervalSeconds | Out-Null }
    if ($urlToOpen) { Open-InChrome $config $urlToOpen }
  } elseif ($fileToOpen) {
    Open-InChrome $config (Join-Path $path $fileToOpen)
  }
}
Write-Log 'Launch sequence complete'
