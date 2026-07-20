# ConextLab NVIDIA Demo Installer & Launcher

PowerShell-first MVP for installing and launching the ConextLab Windows demo stack.

## Files

- `config/demo-config.json` — editable source of truth for install root, repos, ports, models, launch order, readiness checks. Default install root is `%USERPROFILE%/Demo`.
- `scripts/preflight.ps1` — checks installed/missing/partial components.
- `scripts/setup.ps1` — installs or repairs dependencies and repos.
- `scripts/launch.ps1` — starts services in order and opens ready URLs in Chrome.
- `scripts/one-touch.ps1` — setup then launch.
- `scripts/create-shortcuts.ps1` — creates Desktop shortcuts.
- `scripts/build-ui.ps1` — builds the Tkinter UI EXE via PyInstaller (single-file).
- `ui/app.py` — Python 3.12 Tkinter UI that wraps the PowerShell scripts (Preflight / Setup / Launch / One-Touch / Shortcuts / Edit Config / git pull / Open Logs).
- `installer/installer.iss` — Inno Setup script that bundles EXE + scripts + config into one `ConextLabDemoInstallerSetup.exe`.
- `installer/README.md` — full UI build + install + troubleshooting guide.
- `logs/` — timestamped run logs.

## P0 CLI usage

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

## UI + installable EXE

See [`installer-ui/README.md`](installer-ui/README.md) for full build and install instructions.

Quick build (Windows + Python 3.12):

```powershell
.\scripts\build-ui.ps1
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" .\installer\installer.iss
```

Produces `installer\Output\ConextLabDemoInstallerSetup.exe`.

Run the UI directly without building:

```powershell
py -3.12 .\ui\app.py
```

## Notes

- Default Ollama port is `11434`.
- Default model is `gemma4:12b`; edit `config/demo-config.json` if the event requires another model.
- Repo URLs are placeholders under `https://github.com/ConextLab/...`; update if the actual org/user differs.
- ComfyUI installs PyTorch nightly from the configured CUDA index URL, currently `cu128`.
- The UI calls the PowerShell scripts with `-ExecutionPolicy Bypass`; admin is required for Chocolatey/installs.
