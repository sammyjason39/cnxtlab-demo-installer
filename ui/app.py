#!/usr/bin/env python3
"""ConextLab NVIDIA Demo Installer & Launcher - Tkinter UI.

A thin GUI wrapper around the PowerShell scripts in ../scripts/.
All install/launch logic lives in PowerShell; this UI only shells out.
"""

from __future__ import annotations

import os
import subprocess
import sys
import threading
import queue
import webbrowser
from pathlib import Path
from tkinter import Tk, ttk, messagebox
import tkinter as tk


def project_root() -> Path:
    """Resolve the project root (the folder containing scripts/)."""
    here = Path(__file__).resolve().parent
    # ui/ is one level below the project root
    candidate = here.parent
    if (candidate / "scripts").is_dir():
        return candidate
    # If bundled with PyInstaller, EXE sits next to scripts/
    if (here / "scripts").is_dir():
        return here
    return here


def find_powershell() -> str:
    """Return the best available PowerShell executable."""
    for cand in ("pwsh.exe", "powershell.exe", "pwsh", "powershell"):
        try:
            subprocess.run([cand, "-NoProfile", "-Command", "$PSVersionTable"],
                           capture_output=True, timeout=5, check=False)
            return cand
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    return "powershell.exe"


def run_script(script_name: str, config_path: Path, output_q: queue.Queue,
                done_q: queue.Queue, root: Path, extra_args: list[str] | None = None) -> None:
    """Run a PowerShell script and stream its output to the queue."""
    script = root / "scripts" / script_name
    if not script.exists():
        output_q.put(f"Script not found: {script}\r\n")
        done_q.put((script_name, 1))
        return
    args = [
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", str(script),
        "-ConfigPath", str(config_path),
    ]
    if extra_args:
        args.extend(extra_args)
    cmd = [find_powershell()] + args
    output_q.put(f"\r\n=== {script_name} starting ===\r\n")
    try:
        proc = subprocess.Popen(cmd, cwd=str(root),
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, encoding="utf-8", errors="replace",
                                creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        assert proc.stdout is not None
        for line in proc.stdout:
            output_q.put(line)
        proc.wait()
        code = proc.returncode
        output_q.put(f"=== {script_name} {'complete' if code == 0 else 'FAILED (exit ' + str(code) + ')'} ===\r\n")
    except Exception as e:
        output_q.put(f"Exception: {e}\r\n")
        code = 1
    done_q.put((script_name, code))


class InstallerUI:
    def __init__(self, root: Tk) -> None:
        self.root_win = root
        self.root_path = project_root()
        self.config_path = self.root_path / "config" / "demo-config.json"
        self.out_q: queue.Queue[str] = queue.Queue()
        self.done_q: queue.Queue[tuple[str, int]] = queue.Queue()
        self.running = False
        root.title("ConextLab NVIDIA Demo Installer")
        root.geometry("900x650")
        root.minsize(800, 600)
        self._build_ui()
        self._poll_queues()
        self._validate_env()

    def _build_ui(self) -> None:
        pad = {"padx": 8, "pady": 4}

        # Header
        header = ttk.Frame(self.root_win, padding=(10, 10, 10, 0))
        header.pack(fill=tk.X)
        ttk.Label(header, text="ConextLab NVIDIA Demo Installer & Launcher",
                  font=("Segoe UI", 14, "bold")).pack(anchor=tk.W)
        ttk.Label(header, text=f"Project root: {self.root_path}",
                  font=("Segoe UI", 9)).pack(anchor=tk.W, pady=(4, 0))
        ttk.Label(header, text=f"Config: {self.config_path}",
                  font=("Segoe UI", 9)).pack(anchor=tk.W)

        # Status box
        status_frame = ttk.LabelFrame(self.root_win, text="Environment Status", padding=8)
        status_frame.pack(fill=tk.X, padx=10, pady=(8, 4))
        self.status_text = tk.Text(status_frame, height=5, font=("Consolas", 9),
                                   bg="#f0f0f0", relief=tk.FLAT, wrap=tk.WORD)
        self.status_text.pack(fill=tk.X)
        self.status_text.configure(state=tk.DISABLED)

        # Buttons
        btn_frame = ttk.Frame(self.root_win, padding=(10, 4))
        btn_frame.pack(fill=tk.X)
        buttons = [
            ("Preflight Check", self.on_preflight),
            ("Setup / Install", self.on_setup),
            ("Launch Demo", self.on_launch),
            ("One-Touch", self.on_one_touch),
            ("Create Shortcuts", self.on_shortcuts),
            ("Edit Config", self.on_edit_config),
            ("git pull", self.on_pull),
            ("Open Logs", self.on_open_logs),
        ]
        for text, cmd in buttons:
            b = ttk.Button(btn_frame, text=text, command=cmd, width=18)
            b.pack(side=tk.LEFT, padx=2)
            setattr(self, f"_btn_{text.lower().replace(' ', '_').replace('/', '_')}", b)

        # Console log
        log_frame = ttk.LabelFrame(self.root_win, text="Console Output", padding=4)
        log_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=(4, 10))
        self.log_text = tk.Text(log_frame, font=("Consolas", 9),
                                bg="#0a0a0a", fg="#39ff14",
                                wrap=tk.NONE, relief=tk.FLAT)
        log_scroll_y = ttk.Scrollbar(log_frame, orient=tk.VERTICAL,
                                     command=self.log_text.yview)
        log_scroll_x = ttk.Scrollbar(log_frame, orient=tk.HORIZONTAL,
                                      command=self.log_text.xview)
        self.log_text.configure(yscrollcommand=log_scroll_y.set,
                                xscrollcommand=log_scroll_x.set,
                                state=tk.DISABLED)
        self.log_text.grid(row=0, column=0, sticky=tk.NSEW)
        log_scroll_y.grid(row=0, column=1, sticky=tk.NS)
        log_scroll_x.grid(row=1, column=0, sticky=tk.EW)
        log_frame.rowconfigure(0, weight=1)
        log_frame.columnconfigure(0, weight=1)

        # Progress bar
        self.progress = ttk.Progressbar(self.root_win, mode="indeterminate")
        self.progress.pack(fill=tk.X, padx=10, pady=(0, 10))

    def _validate_env(self) -> None:
        root = self.root_path
        checks = [
            ("Project root", root.is_dir()),
            ("Config", self.config_path.is_file()),
            ("preflight.ps1", (root / "scripts" / "preflight.ps1").is_file()),
            ("setup.ps1", (root / "scripts" / "setup.ps1").is_file()),
            ("launch.ps1", (root / "scripts" / "launch.ps1").is_file()),
        ]
        lines = [f"{name:14} .. {'OK' if ok else 'MISSING'}" for name, ok in checks]
        self.status_text.configure(state=tk.NORMAL)
        self.status_text.delete("1.0", tk.END)
        self.status_text.insert("1.0", "\n".join(lines))
        self.status_text.configure(state=tk.DISABLED)

    # ---------- Button handlers ----------

    def _start_script(self, script_name: str, extra_args: list[str] | None = None) -> None:
        if self.running:
            self._append_log("A script is already running. Wait for it to finish.\r\n")
            return
        self.running = True
        self.progress.start(15)
        self._set_buttons_state(tk.DISABLED)
        t = threading.Thread(target=run_script,
                              args=(script_name, self.config_path, self.out_q, self.done_q,
                                    self.root_path, extra_args),
                              daemon=True)
        t.start()

    def on_preflight(self) -> None:
        self._start_script("preflight.ps1")

    def on_setup(self) -> None:
        self._start_script("setup.ps1")

    def on_launch(self) -> None:
        self._start_script("launch.ps1")

    def on_one_touch(self) -> None:
        self._start_script("one-touch.ps1")

    def on_shortcuts(self) -> None:
        self._start_script("create-shortcuts.ps1")

    def on_edit_config(self) -> None:
        if not self.config_path.is_file():
            self._append_log(f"Config not found: {self.config_path}\r\n")
            return
        try:
            if os.name == "nt":
                os.startfile(str(self.config_path), "edit")  # type: ignore[attr-defined]
            else:
                subprocess.run(["xdg-open", str(self.config_path)], check=False)
        except Exception as e:
            self._append_log(f"Could not open editor: {e}\r\n")

    def on_pull(self) -> None:
        if self.running:
            self._append_log("A script is already running.\r\n")
            return
        self.running = True
        self.progress.start(15)
        self._set_buttons_state(tk.DISABLED)
        def _pull() -> None:
            self.out_q.put("\r\n=== git pull ===\r\n")
            try:
                proc = subprocess.run(["git", "-C", str(self.root_path), "pull", "--ff-only"],
                                      capture_output=True, text=True, encoding="utf-8",
                                      errors="replace", timeout=120)
                self.out_q.put(proc.stdout + proc.stderr + "\r\n")
                self.done_q.put(("git pull", proc.returncode))
            except Exception as e:
                self.out_q.put(f"git pull failed: {e}\r\n")
                self.done_q.put(("git pull", 1))
        threading.Thread(target=_pull, daemon=True).start()

    def on_open_logs(self) -> None:
        log_dir = self.root_path / "logs"
        if not log_dir.is_dir():
            self._append_log(f"No logs dir: {log_dir}\r\n")
            return
        try:
            if os.name == "nt":
                subprocess.run(["explorer.exe", str(log_dir)], check=False)
            else:
                subprocess.run(["xdg-open", str(log_dir)], check=False)
        except Exception as e:
            self._append_log(f"Could not open logs: {e}\r\n")

    # ---------- Queue polling ----------

    def _poll_queues(self) -> None:
        try:
            while True:
                msg = self.out_q.get_nowait()
                self._append_log(msg)
        except queue.Empty:
            pass
        try:
            name, code = self.done_q.get_nowait()
            if self.running:
                self.running = False
                self.progress.stop()
                self._set_buttons_state(tk.NORMAL)
                self._validate_env()
        except queue.Empty:
            pass
        self.root_win.after(100, self._poll_queues)

    def _append_log(self, text: str) -> None:
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.insert(tk.END, text)
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)

    def _set_buttons_state(self, state: str) -> None:
        for child in self.root_win.winfo_children():
            self._disable_buttons_in(child, state)

    def _disable_buttons_in(self, widget: tk.Misc, state: str) -> None:
        if isinstance(widget, ttk.Button):
            widget.configure(state=state)
        for child in widget.winfo_children():
            self._disable_buttons_in(child, state)


def main() -> int:
    root = Tk()
    try:
        style = ttk.Style()
        if "vista" in style.theme_names():
            style.theme_use("vista")
    except Exception:
        pass
    InstallerUI(root)
    root.mainloop()
    return 0


if __name__ == "__main__":
    sys.exit(main())