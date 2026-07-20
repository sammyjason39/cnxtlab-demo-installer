namespace ConextLabDemoInstaller;

partial class MainForm
{
    private System.ComponentModel.IContainer? components = null;

    private Label lblTitle = null!;
    private Label lblRoot = null!;
    private Label lblConfig = null!;
    private TextBox txtStatus = null!;
    private Button btnPreflight = null!;
    private Button btnSetup = null!;
    private Button btnLaunch = null!;
    private Button btnOneTouch = null!;
    private Button btnShortcuts = null!;
    private Button btnEditConfig = null!;
    private Button btnPull = null!;
    private Button btnOpenLogs = null!;
    private TextBox txtLog = null!;
    private ProgressBar progressBar = null!;

    protected override void Dispose(bool disposing)
    {
        if (disposing && components != null) components.Dispose();
        base.Dispose(disposing);
    }

    private void InitializeComponent()
    {
        lblTitle = new Label();
        lblRoot = new Label();
        lblConfig = new Label();
        txtStatus = new TextBox();
        btnPreflight = new Button();
        btnSetup = new Button();
        btnLaunch = new Button();
        btnOneTouch = new Button();
        btnShortcuts = new Button();
        btnEditConfig = new Button();
        btnPull = new Button();
        btnOpenLogs = new Button();
        txtLog = new TextBox();
        progressBar = new ProgressBar();
        SuspendLayout();

        // lblTitle
        lblTitle.Text = "ConextLab NVIDIA Demo Installer & Launcher";
        lblTitle.Font = new Font("Segoe UI", 14F, FontStyle.Bold);
        lblTitle.Location = new Point(15, 12);
        lblTitle.Size = new Size(560, 28);

        // lblRoot
        lblRoot.Location = new Point(15, 45);
        lblRoot.Size = new Size(760, 20);
        lblRoot.Font = new Font("Segoe UI", 9F);

        // lblConfig
        lblConfig.Location = new Point(15, 65);
        lblConfig.Size = new Size(760, 20);
        lblConfig.Font = new Font("Segoe UI", 9F);

        // txtStatus
        txtStatus.Location = new Point(15, 90);
        txtStatus.Size = new Size(760, 80);
        txtStatus.Multiline = true;
        txtStatus.ReadOnly = true;
        txtStatus.ScrollBars = ScrollBars.Vertical;
        txtStatus.Font = new Font("Consolas", 9F);

        // Action buttons - left column
        var bx = 15;
        var by = 180;
        var bw = 180;
        var bh = 38;
        var gap = 46;

        SetupButton(btnPreflight, "Preflight Check", bx, by, bw, bh);
        SetupButton(btnSetup, "Setup / Install", bx, by + gap, bw, bh);
        SetupButton(btnLaunch, "Launch Demo", bx, by + gap * 2, bw, bh);
        SetupButton(btnOneTouch, "One-Touch (Setup+Launch)", bx, by + gap * 3, bw, bh);

        // right column
        var bx2 = bx + bw + 20;
        SetupButton(btnShortcuts, "Create Shortcuts", bx2, by, bw, bh);
        SetupButton(btnEditConfig, "Edit Config", bx2, by + gap, bw, bh);
        SetupButton(btnPull, "git pull (update)", bx2, by + gap * 2, bw, bh);
        SetupButton(btnOpenLogs, "Open Logs Folder", bx2, by + gap * 3, bw, bh);

        RegisterButton(btnPreflight, "preflight.ps1");
        RegisterButton(btnSetup, "setup.ps1");
        RegisterButton(btnLaunch, "launch.ps1");
        RegisterButton(btnOneTouch, "one-touch.ps1");
        RegisterButton(btnShortcuts, "create-shortcuts.ps1");

        // txtLog
        txtLog.Location = new Point(15, by + gap * 4 + 10);
        txtLog.Size = new Size(760, 260);
        txtLog.Multiline = true;
        txtLog.ReadOnly = true;
        txtLog.ScrollBars = ScrollBars.Both;
        txtLog.Font = new Font("Consolas", 9F);
        txtLog.WordWrap = false;
        txtLog.BackColor = Color.Black;
        txtLog.ForeColor = Color.LimeGreen;

        // progressBar
        progressBar.Location = new Point(15, by + gap * 4 + 10 + 265);
        progressBar.Size = new Size(760, 18);
        progressBar.Style = ProgressBarStyle.Marquee;
        progressBar.Visible = false;

        // MainForm
        AutoScaleDimensions = new SizeF(7F, 15F);
        AutoScaleMode = AutoScaleMode.Font;
        ClientSize = new Size(790, 560);
        Controls.AddRange(new Control[] {
            lblTitle, lblRoot, lblConfig, txtStatus,
            btnPreflight, btnSetup, btnLaunch, btnOneTouch,
            btnShortcuts, btnEditConfig, btnPull, btnOpenLogs,
            txtLog, progressBar
        });
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        Load += MainForm_Load;
        ResumeLayout(false);
        PerformLayout();

        // Wire events
        btnPreflight.Click += btnPreflight_Click;
        btnSetup.Click += btnSetup_Click;
        btnLaunch.Click += btnLaunch_Click;
        btnOneTouch.Click += btnOneTouch_Click;
        btnShortcuts.Click += btnShortcuts_Click;
        btnEditConfig.Click += btnEditConfig_Click;
        btnPull.Click += btnPull_Click;
        btnOpenLogs.Click += btnOpenLogs_Click;
    }

    private void SetupButton(Button b, string text, int x, int y, int w, int h)
    {
        b.Text = text;
        b.Location = new Point(x, y);
        b.Size = new Size(w, h);
        b.Font = new Font("Segoe UI", 9F);
        b.FlatStyle = FlatStyle.System;
    }
}