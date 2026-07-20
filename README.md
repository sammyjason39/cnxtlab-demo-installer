# ConextLab NVIDIA Demo Installer & Launcher

PowerShell-first MVP for installing and launching the ConextLab Windows demo stack.

## Files

- `config/demo-config.json` — editable source of truth for install root, repos, ports, models, launch order, readiness checks. Default install root is `%USERPROFILE%/Demo`.
- `scripts/preflight.ps1` — checks installed/missing/partial components.
- `scripts/setup.ps1` — installs or repairs dependencies and repos.
- `scripts/launch.ps1` — starts services in order and opens ready URLs in Chrome.
- `scripts/one-touch.ps1` — setup then launch.
- `scripts/create-shortcuts.ps1` — creates Desktop shortcuts.
- `scripts/build-ui.ps1` — builds the WinForms UI EXE (single-file, self-contained).
- `installer-ui/` — WinForms UI source (`ConextLabDemoInstaller.csproj`, `MainForm.cs`, `MainForm.Designer.cs`, `Program.cs`) + Inno Setup installer (`installer.iss`) + build/install guide (`README.md`).
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

Quick build (Windows + .NET 8 SDK):

```powershell
.\scripts\build-ui.ps1
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" .\installer-ui\installer.iss
```

Produces `installer-ui\Output\ConextLabDemoInstallerSetup.exe`.

## Notes

- Default Ollama port is `11434`.
- Default model is `gemma4:12b`; edit `config/demo-config.json` if the event requires another model.
- Repo URLs are placeholders under `https://github.com/ConextLab/...`; update if the actual org/user differs.
- ComfyUI installs PyTorch nightly from the configured CUDA index URL, currently `cu128`.
- The UI calls the PowerShell scripts with `-ExecutionPolicy Bypass`; admin is required for Chocolatey/installs.
