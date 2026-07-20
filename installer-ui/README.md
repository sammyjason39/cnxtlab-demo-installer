# ConextLab NVIDIA Demo Installer — UI + Installer Build Guide

This package has two layers:

1. **PowerShell core** (`scripts/`) — the actual install/launch logic. Runs standalone from the terminal.
2. **WinForms UI** (`installer-ui/`) — a simple Windows GUI that calls the PowerShell scripts, plus an Inno Setup installer that bundles everything into one installable `.exe`.

## Prerequisites (build machine, Windows)

- .NET 8 SDK: <https://dotnet.microsoft.com/download/dotnet/8.0>
- Inno Setup 6: <https://jrsoftware.org/isdl.php>
- Git (to clone/pull this repo)
- PowerShell 5.1+ (built into Windows 10/11)

## Build steps

From the repo root on Windows:

```powershell
# 1. Build the single-file WinForms EXE
.\scripts\build-ui.ps1
#    -> installer-ui\bin\Release\net8.0-windows\win-x64\publish\ConextLabDemoInstaller.exe

# 2. Build the installer bundle
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" .\installer-ui\installer.iss
#    -> installer-ui\Output\ConextLabDemoInstallerSetup.exe
```

You now have an installable `ConextLabDemoInstallerSetup.exe` you can copy to the demo laptop.

## Install on the demo laptop

1. Copy `ConextLabDemoInstallerSetup.exe` to the demo laptop.
2. Right-click → **Run as administrator**.
3. Accept the default install path: `C:\Program Files\ConextLabDemoInstaller`.
4. (Optional) tick "Create desktop icon".
5. Click **Finish** — the UI launches.

The installer copies:
- `ConextLabDemoInstaller.exe` (the UI)
- `scripts\*.ps1` and `scripts\lib\*.ps1`
- `config\demo-config.json` (only if not already present — your edits are preserved on upgrade)
- `README.md`
- empty `logs\` folder

## Using the UI

| Button | What it does |
|---|---|
| **Preflight Check** | Runs `preflight.ps1` — shows installed/missing/partial per component |
| **Setup / Install** | Runs `setup.ps1` — installs or repairs all dependencies and repos (no launch) |
| **Launch Demo** | Runs `launch.ps1` — starts services in order, opens ready URLs in Chrome |
| **One-Touch** | Runs `one-touch.ps1` — setup then launch |
| **Create Shortcuts** | Adds Desktop shortcuts for Setup, Launch, One-Touch |
| **Edit Config** | Opens `config\demo-config.json` in Notepad |
| **git pull** | Pulls latest scripts from GitHub (update the tool itself) |
| **Open Logs Folder** | Opens `logs\` in Explorer for post-mortem |

The black console panel shows live output from every script run.

## First-time demo laptop flow

1. Run the installer EXE as admin.
2. Launch the UI from the Start Menu / Desktop icon.
3. Click **Edit Config** — confirm `installRoot`, repo URLs, ports, Ollama models.
4. Click **One-Touch**. Wait. Watch the console panel.
5. When it finishes, every service is running and every app URL is open in Chrome.

## Updating the tool on the demo laptop

Two options:

- **UI button:** click **git pull** — pulls latest scripts into the install folder. Requires git installed and the install folder to be a git repo. Easiest path: clone the repo into `C:\Program Files\ConextLabDemoInstaller` instead of using the installer, then the git pull button works directly.
- **Re-run installer:** download the latest `ConextLabDemoInstallerSetup.exe` and run it again. Config is preserved.

## Troubleshooting

- **SmartScreen warning:** the EXE is unsigned. Click **More info → Run anyway**. For v1 this is single-supervised-user so signing is non-blocking.
- **"Script not found" in UI:** the UI could not locate `scripts\` next to the EXE. Reinstall, or make sure the install folder has the `scripts\` directory.
- **PowerShell execution policy errors:** the UI runs scripts with `-ExecutionPolicy Bypass`, so this should not happen. If it does, run `Set-ExecutionPolicy Bypass -Scope Process -Force` in an admin shell before launching the UI.
- **Chocolatey not installed:** `setup.ps1` installs it automatically on first run (requires admin).
- **PyTorch CUDA check fails:** confirm the GPU driver is current and the `torchIndexUrl` in config matches your CUDA capability. RTX 5080 uses `cu128`.

## Build verification checklist

- [ ] `.\scripts\build-ui.ps1` succeeds and prints the EXE path
- [ ] `ConextLabDemoInstaller.exe` launches and shows the UI
- [ ] **Preflight Check** button runs and populates the status/log panel
- [ ] `ISCC.exe installer-ui\installer.iss` produces `ConextLabDemoInstallerSetup.exe`
- [ ] Running the setup EXE installs and launches the UI
- [ ] Installed UI can run **Preflight Check** against the bundled scripts