param([string]$ConfigPath = "config/demo-config.json")
. "$PSScriptRoot/lib/Common.ps1"
. "$PSScriptRoot/lib/Detection.ps1"
$log = Initialize-Log 'preflight'
$config = Get-DemoConfig $ConfigPath
Write-Log "Preflight log: $log"
Write-Log "Install root: $(Get-InstallRoot $config)"
$gpu = Get-GpuInfo
Write-Log "GPU: $($gpu.Detail)"
Test-ComponentStatus $config | Format-Table -AutoSize
Write-Log "Preflight complete"
