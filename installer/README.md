# ConextLab NVIDIA Demo Installer — UI + Installer Build Guide

Two layers:

1. **PowerShell core** (`../scripts/`) — actual install/launch logic. Runs standalone from the terminal.
2. **Python Tkinter UI** (`../ui/app.py`) — simple Windows GUI that calls the PowerShell scripts. Bundled into a single EXE with PyInstaller, then packaged with Inno Setup into one installable `ConextLabDemoInstallerSetup.exe`.

## Prerequisites (build machine, Windows)

- Python 3.12 — <https://www.python.org/downloads/> (the project already needs it for ComfyUI)
- Inno Setup 6 — <https://jrsoftware.org/isdl.php> or `winget install JRSoftware.InnoSetup -e`
- Git (to clone/pull this repo)

No .NET SDK needed. Python is the only runtime.

## Build steps

From the repo root on Windows:

```powershell
# 1. Build the single-file UI EXE (PyInstaller)
.\scripts\build-ui.ps1
#    -> ui\dist\ConextLabDemoInstaller.exe

# 2. Build the installer bundle (Inno Setup)
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" .\installer\installer.iss
#    -> installer\Output\ConextLabDemoInstallerSetup.exe
```

If `ISCC.exe` is not at that exact path, locate it:

```powershell
$isscc = (Get-ChildItem "C:\Program Files*" -Filter ISCC.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
& $isscc .\installer\installer.iss
```

You now have an installable `ConextLabDemoInstallerSetup.exe` to copy to the demo laptop.

## Run the UI without building the installer

You can run the UI directly with Python (no EXE build needed) for quick testing:

```powershell
py -3.12 ..\ui\app.py
```

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
| **Edit Config** | Opens `config\demo-config.json` in the default editor |
| **git pull** | Pulls latest scripts from GitHub (update the tool itself) |
| **Open Logs** | Opens `logs\` in Explorer for post-mortem |

The black console panel shows live output from every script run.

## First-time demo laptop flow

1. Run the installer EXE as admin.
2. Launch the UI from the Start Menu / Desktop icon.
3. Click **Edit Config** — confirm `installRoot`, repo URLs, ports, Ollama models.
4. Click **One-Touch**. Wait. Watch the console panel.
5. When it finishes, every service is running and every app URL is open in Chrome.

## Updating the tool on the demo laptop

Two options:

- **UI button:** click **git pull** — pulls latest scripts into the install folder. Requires git installed and the install folder to be a git repo. Easiest path: clone the repo into the install folder instead of using the installer, then the git pull button works directly.
- **Re-run installer:** download the latest `ConextLabDemoInstallerSetup.exe` and run it again. Config is preserved.

## Troubleshooting

- **SmartScreen warning:** the EXE is unsigned. Click **More info → Run anyway**. For v1 this is single-supervised-user so signing is non-blocking.
- **"Script not found" in UI:** the UI could not locate `scripts\` next to the EXE. Reinstall, or make sure the install folder has the `scripts\` directory.
- **PowerShell execution policy errors:** the UI runs scripts with `-ExecutionPolicy Bypass`, so this should not happen. If it does, run `Set-ExecutionPolicy Bypass -Scope Process -Force` in an admin shell before launching the UI.
- **Chocolatey not installed:** `setup.ps1` installs it automatically on first run (requires admin).
- **PyTorch CUDA check fails:** confirm the GPU driver is current and the `torchIndexUrl` in config matches your CUDA capability. RTX 5080 uses `cu128`.
- **PyInstaller build fails:** ensure `py -3.12 -m pip install --upgrade pyinstaller` succeeded and you are on a 64-bit Python 3.12.

## Build verification checklist

- [ ] `.\scripts\build-ui.ps1` succeeds and prints the EXE path
- [ ] `ui\dist\ConextLabDemoInstaller.exe` launches and shows the UI
- [ ] **Preflight Check** button runs and populates the status/log panel
- [ ] `ISCC.exe .\installer\installer.iss` produces `ConextLabDemoInstallerSetup.exe`
- [ ] Running the setup EXE installs and launches the UI
- [ ] Installed UI can run **Preflight Check** against the bundled scripts