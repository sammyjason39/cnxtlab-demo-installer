param([string]$ConfigPath = "config/demo-config.json")
. "$PSScriptRoot/lib/Common.ps1"
$root = Get-ProjectRoot
$desktop = [Environment]::GetFolderPath('Desktop')
$wsh = New-Object -ComObject WScript.Shell
$items = @(
  @{Name='ConextLab Demo Setup'; Target="powershell.exe"; Args="-ExecutionPolicy Bypass -File `"$root\scripts\setup.ps1`" -ConfigPath `"$ConfigPath`""},
  @{Name='ConextLab Launch Demo'; Target="powershell.exe"; Args="-ExecutionPolicy Bypass -File `"$root\scripts\launch.ps1`" -ConfigPath `"$ConfigPath`""},
  @{Name='ConextLab One Touch'; Target="powershell.exe"; Args="-ExecutionPolicy Bypass -File `"$root\scripts\one-touch.ps1`" -ConfigPath `"$ConfigPath`""}
)
foreach ($i in $items) {
  $lnk = $wsh.CreateShortcut((Join-Path $desktop ($i.Name + '.lnk')))
  $lnk.TargetPath = $i.Target
  $lnk.Arguments = $i.Args
  $lnk.WorkingDirectory = $root
  $lnk.Save()
}
Write-Host 'Shortcuts created on Desktop.'
