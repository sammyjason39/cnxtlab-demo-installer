. "$PSScriptRoot/Common.ps1"

function Get-VersionOutput { param([string]$Command) try { (cmd.exe /c $Command 2>$null) -join "`n" } catch { $null } }

function Test-ComponentStatus {
  param([Parameter(Mandatory)]$Config)
  $rows = @()
  foreach ($item in @(
    @{Name='Node.js'; Command='node -v'},
    @{Name='Python'; Command='py -3.12 --version'},
    @{Name='Git'; Command='git --version'},
    @{Name='GitHub CLI'; Command='gh --version'},
    @{Name='Ollama'; Command='ollama --version'},
    @{Name='n8n'; Command='n8n --version'},
    @{Name='Openclaw'; Command='openclaw --version'}
  )) {
    $out = Get-VersionOutput $item.Command
    $rows += [pscustomobject]@{ Component=$item.Name; Status= if ($out) {'installed'} else {'missing'}; Detail=($out -split "`n" | Select-Object -First 1) }
  }
  $comfyPath = Resolve-DemoPath $Config $Config.comfyui.path
  $rows += [pscustomobject]@{ Component='ComfyUI'; Status= if ((Test-Path (Join-Path $comfyPath 'main.py')) -and (Test-Path (Join-Path $comfyPath 'venv'))) {'installed'} elseif (Test-Path $comfyPath) {'partial'} else {'missing'}; Detail=$comfyPath }
  foreach ($repo in $Config.repositories) {
    $path = Resolve-DemoPath $Config $repo.path
    $rows += [pscustomobject]@{ Component=$repo.name; Status= if (Test-Path (Join-Path $path '.git')) {'installed'} elseif (Test-Path $path) {'partial'} else {'missing'}; Detail=$path }
  }
  return $rows
}

function Get-GpuInfo {
  $out = Get-VersionOutput 'nvidia-smi --query-gpu=name,memory.total,compute_cap --format=csv,noheader'
  if (!$out) { return [pscustomobject]@{ Present=$false; Detail='nvidia-smi unavailable' } }
  [pscustomobject]@{ Present=$true; Detail=$out.Trim() }
}
