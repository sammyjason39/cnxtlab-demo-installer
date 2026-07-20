using System.Diagnostics;
using System.IO;
using System.Text;

namespace ConextLabDemoInstaller;

public partial class MainForm : Form
{
    private string _root = string.Empty;
    private string _configPath = string.Empty;

    public MainForm()
    {
        InitializeComponent();
        ResolveRoot();
        _configPath = Path.Combine(_root, "config", "demo-config.json");
        Text = "ConextLab NVIDIA Demo Installer";
    }

    private void ResolveRoot()
    {
        // 1. EXE directory
        _root = AppContext.BaseDirectory;
        // 2. If running from installer/, go up to project root
        var scriptsDir = Path.Combine(_root, "scripts");
        if (!Directory.Exists(scriptsDir))
        {
            var parent = Directory.GetParent(_root);
            if (parent != null && Directory.Exists(Path.Combine(parent.FullName, "scripts")))
                _root = parent.FullName;
        }
    }

    private void MainForm_Load(object sender, EventArgs e)
    {
        lblRoot.Text = $"Project root: {_root}";
        lblConfig.Text = $"Config: {_configPath}";
        ValidateEnvironment();
    }

    private void ValidateEnvironment()
    {
        var sb = new StringBuilder();
        sb.AppendLine($"Project root .. {(Directory.Exists(_root) ? "OK" : "MISSING")}");
        sb.AppendLine($"Config ........ {(File.Exists(_configPath) ? "OK" : "MISSING")}");
        sb.AppendLine($"preflight.ps1 . {(File.Exists(Path.Combine(_root, "scripts", "preflight.ps1")) ? "OK" : "MISSING")}");
        sb.AppendLine($"setup.ps1 ..... {(File.Exists(Path.Combine(_root, "scripts", "setup.ps1")) ? "OK" : "MISSING")}");
        sb.AppendLine($"launch.ps1 .... {(File.Exists(Path.Combine(_root, "scripts", "launch.ps1")) ? "OK" : "MISSING")}");
        txtStatus.Text = sb.ToString();
    }

    private async void btnPreflight_Click(object sender, EventArgs e)
        => await RunScript("preflight.ps1", "Preflight");

    private async void btnSetup_Click(object sender, EventArgs e)
        => await RunScript("setup.ps1", "Setup", "-LaunchAfterSetup:$false");

    private async void btnLaunch_Click(object sender, EventArgs e)
        => await RunScript("launch.ps1", "Launch");

    private async void btnOneTouch_Click(object sender, EventArgs e)
        => await RunScript("one-touch.ps1", "One-Touch");

    private async void btnShortcuts_Click(object sender, EventArgs e)
        => await RunScript("create-shortcuts.ps1", "Create Shortcuts");

    private async void btnEditConfig_Click(object sender, EventArgs e)
    {
        if (!File.Exists(_configPath)) { AppendLog($"Config not found: {_configPath}\r\n"); return; }
        if (OperatingSystem.IsWindows())
            Process.Start(new ProcessStartInfo("notepad.exe", _configPath) { UseShellExecute = true });
        else
            AppendLog("Manual edit needed on non-Windows.\r\n");
        await Task.CompletedTask;
    }

    private async void btnPull_Click(object sender, EventArgs e)
    {
        btnPull.Enabled = false;
        AppendLog("git pull ...\r\n");
        try
        {
            var (code, output) = await RunProcessAsync("git", $"-C \"{_root}\" pull --ff-only");
            AppendLog(output + "\r\n");
            AppendLog(code == 0 ? "Pull complete.\r\n" : $"Pull failed (exit {code}).\r\n");
        }
        finally { btnPull.Enabled = true; }
    }

    private async void btnOpenLogs_Click(object sender, EventArgs e)
    {
        var logDir = Path.Combine(_root, "logs");
        if (!Directory.Exists(logDir)) { AppendLog($"No logs dir: {logDir}\r\n"); return; }
        if (OperatingSystem.IsWindows())
            Process.Start(new ProcessStartInfo("explorer.exe", logDir) { UseShellExecute = true });
        await Task.CompletedTask;
    }

    private async Task RunScript(string scriptName, string label, params string[] extraArgs)
    {
        var btn = senderButtonMap.FirstOrDefault(kv => kv.Value == scriptName).Key;
        if (btn != null) btn.Enabled = false;
        SetBusy(true);
        AppendLog($"\r\n=== {label} starting ===\r\n");
        try
        {
            var scriptPath = Path.Combine(_root, "scripts", scriptName);
            if (!File.Exists(scriptPath))
            {
                AppendLog($"Script not found: {scriptPath}\r\n");
                return;
            }
            var args = new StringBuilder($"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\" -ConfigPath \"{_configPath}\"");
            foreach (var a in extraArgs) args.Append(' ').Append(a);
            var (code, output) = await RunProcessAsync("powershell.exe", args.ToString(), workingDir: _root);
            AppendLog(output + "\r\n");
            AppendLog(code == 0
                ? $"=== {label} complete ===\r\n"
                : $"=== {label} FAILED (exit {code}) ===\r\n");
        }
        catch (Exception ex)
        {
            AppendLog($"Exception: {ex.Message}\r\n");
        }
        finally
        {
            if (btn != null) btn.Enabled = true;
            SetBusy(false);
        }
    }

    private void SetBusy(bool busy)
    {
        progressBar.Visible = busy;
        progressBar.Style = ProgressBarStyle.Marquee;
        progressBar.MarqueeAnimationSpeed = busy ? 30 : 0;
    }

    private void AppendLog(string text)
    {
        if (txtLog.InvokeRequired) txtLog.Invoke(() => AppendLog(text));
        else
        {
            txtLog.AppendText(text);
            txtLog.SelectionStart = txtLog.TextLength;
            txtLog.ScrollToCaret();
        }
    }

    private static async Task<(int exitCode, string output)> RunProcessAsync(string fileName, string arguments, string? workingDir = null)
    {
        var psi = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8,
        };
        if (workingDir != null) psi.WorkingDirectory = workingDir;

        using var p = new Process { StartInfo = psi };
        var sb = new StringBuilder();
        p.OutputDataReceived += (_, e) => { if (e.Data != null) lock (sb) sb.AppendLine(e.Data); };
        p.ErrorDataReceived += (_, e) => { if (e.Data != null) lock (sb) sb.AppendLine(e.Data); };

        p.Start();
        p.BeginOutputReadLine();
        p.BeginErrorReadLine();
        await p.WaitForExitAsync();
        return (p.ExitCode, sb.ToString());
    }

    private readonly Dictionary<Button, string> senderButtonMap = new();

    private void RegisterButton(Button btn, string scriptName)
        => senderButtonMap[btn] = scriptName;
}