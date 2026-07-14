# ConextLab NVIDIA Demo Installer & Launcher

PowerShell-first MVP for installing and launching the ConextLab Windows demo stack.

## Files

- `config/demo-config.json` — editable source of truth for install root, repos, ports, models, launch order, readiness checks. Default install root is `%USERPROFILE%/Demo`.
- `scripts/preflight.ps1` — checks installed/missing/partial components.
- `scripts/setup.ps1` — installs or repairs dependencies and repos.
- `scripts/launch.ps1` — starts services in order and opens ready URLs in Chrome.
- `scripts/one-touch.ps1` — setup then launch.
- `scripts/create-shortcuts.ps1` — creates Desktop shortcuts.
- `logs/` — timestamped run logs.

## First run on Windows

Open PowerShell as Administrator:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\preflight.ps1
.\scripts\setup.ps1
.\scripts\launch.ps1
```

One-touch flow:

```powershell
.\scripts\one-touch.ps1
```

Create shortcuts:

```powershell
.\scripts\create-shortcuts.ps1
```

## Notes

- Default Ollama port is `11434`.
- Default model is `gemma4:12b`; edit `config/demo-config.json` if the event requires another model.
- Repo URLs are placeholders under `https://github.com/ConextLab/...`; update if the actual org/user differs.
- ComfyUI installs PyTorch nightly from the configured CUDA index URL, currently `cu128`.
- P0 is script-core first. EXE wrapping can be added after the scripts pass on the reference laptop.
