using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace AGYPortable
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class MainForm : Form
    {
        private string _appDir;
        private string _dataRoot;
        private string _coreExePath;
        private string _binDir;
        private string _portableTokenPath;
        private string _portableHomeDir;
        private string _hostTokenPath;
        private string _hostGeminiDir;
        private string _hostAgyExe;

        // Status labels
        private Label _lblPath;
        private Label _lblCoreStatus;
        private Label _lblUsbAuthStatus;
        private Label _lblHostAuthStatus;

        // Buttons
        private Button _btnImport;
        private Button _btnExport;
        private Button _btnClearUsb;
        private Button _btnSignIn;

        private Button _btnLaunchAgy;
        private Button _btnLaunchShell;
        private Button _btnOpenData;
        private Button _btnOpenConversations;
        private Button _btnRefresh;
        private Button _btnDownloadCore;

        private ToolTip _toolTip;

        public MainForm()
        {
            InitializePaths();
            InitializeComponent();
            RefreshStatus();
        }

        private void InitializePaths()
        {
            _appDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
            string parentDir = Directory.GetParent(_appDir) != null ? Directory.GetParent(_appDir).FullName.TrimEnd('\\') : _appDir;

            if (Directory.Exists(Path.Combine(parentDir, "data")) || File.Exists(Path.Combine(parentDir, "README.md")) || Directory.Exists(Path.Combine(parentDir, "macOS")))
            {
                _dataRoot = Path.Combine(parentDir, "data");
            }
            else
            {
                _dataRoot = Path.Combine(_appDir, "data");
            }

            _binDir = Path.Combine(_appDir, "bin");
            _coreExePath = Path.Combine(_binDir, "agy.exe");

            _portableHomeDir = Path.Combine(_dataRoot, "home");
            string portableGeminiDir = Path.Combine(_portableHomeDir, ".gemini");
            _portableTokenPath = Path.Combine(portableGeminiDir, "jetski-standalone-oauth-token");

            string hostProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            _hostGeminiDir = Path.Combine(hostProfile, ".gemini");
            _hostTokenPath = Path.Combine(_hostGeminiDir, "jetski-standalone-oauth-token");

            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            _hostAgyExe = Path.Combine(localAppData, "agy", "bin", "agy.exe");
        }

        private void InitializeComponent()
        {
            this.Text = "Antigravity Portable Hub (Windows)";
            this.ClientSize = new Size(565, 410);
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Font = new Font("Segoe UI", 9f, FontStyle.Regular);

            _toolTip = new ToolTip
            {
                AutoPopDelay = 8000,
                InitialDelay = 0,
                ReshowDelay = 0,
                ShowAlways = true
            };

            this.Deactivate += (s, e) => _toolTip.Hide(this);

            // 1. GroupBox: Status
            GroupBox gbStatus = new GroupBox
            {
                Text = "Status",
                Location = new Point(15, 12),
                Size = new Size(535, 122)
            };

            _lblPath = new Label
            {
                Location = new Point(15, 23),
                Size = new Size(505, 20),
                Text = "Location: " + _appDir + " (Data: " + _dataRoot + ")"
            };

            _lblCoreStatus = new Label
            {
                Location = new Point(15, 46),
                Size = new Size(505, 20),
                Text = "CLI Binary: Checking..."
            };

            _lblUsbAuthStatus = new Label
            {
                Location = new Point(15, 69),
                Size = new Size(505, 20),
                Text = "USB Login: Checking..."
            };

            _lblHostAuthStatus = new Label
            {
                Location = new Point(15, 92),
                Size = new Size(505, 20),
                Text = "Host PC Login: Checking..."
            };

            gbStatus.Controls.Add(_lblPath);
            gbStatus.Controls.Add(_lblCoreStatus);
            gbStatus.Controls.Add(_lblUsbAuthStatus);
            gbStatus.Controls.Add(_lblHostAuthStatus);
            this.Controls.Add(gbStatus);

            // 2. GroupBox: Credentials
            GroupBox gbAuth = new GroupBox
            {
                Text = "Login & Credentials",
                Location = new Point(15, 144),
                Size = new Size(535, 115)
            };

            _btnImport = new Button
            {
                Text = "Import Host Login",
                Location = new Point(15, 26),
                Size = new Size(160, 32),
                UseVisualStyleBackColor = true
            };
            _btnImport.Click += BtnImport_Click;
            RegisterButton(_btnImport, 
                "Copies your existing login credentials from this PC to the USB drive so you don't need to re-login.");

            _btnSignIn = new Button
            {
                Text = "Sign In via Browser",
                Location = new Point(187, 26),
                Size = new Size(160, 32),
                UseVisualStyleBackColor = true
            };
            _btnSignIn.Click += BtnSignIn_Click;
            RegisterButton(_btnSignIn, 
                "Opens Google OAuth in your default web browser to log into Antigravity and save the token directly on the USB drive.");

            _btnClearUsb = new Button
            {
                Text = "Clear USB Login",
                Location = new Point(360, 26),
                Size = new Size(160, 32),
                UseVisualStyleBackColor = true
            };
            _btnClearUsb.Click += BtnClearUsb_Click;
            RegisterButton(_btnClearUsb, 
                "Deletes the login token from this USB drive for safe lending. Your conversations, configs, and projects remain intact.");

            _btnExport = new Button
            {
                Text = "Export Login to Host",
                Location = new Point(15, 68),
                Size = new Size(160, 32),
                UseVisualStyleBackColor = true
            };
            _btnExport.Click += BtnExport_Click;
            RegisterButton(_btnExport, 
                "Copies the USB login token onto this computer's local user profile (~/.gemini).");

            gbAuth.Controls.Add(_btnImport);
            gbAuth.Controls.Add(_btnSignIn);
            gbAuth.Controls.Add(_btnClearUsb);
            gbAuth.Controls.Add(_btnExport);
            this.Controls.Add(gbAuth);

            // 3. GroupBox: Actions
            GroupBox gbLaunch = new GroupBox
            {
                Text = "Actions",
                Location = new Point(15, 269),
                Size = new Size(535, 125)
            };

            _btnLaunchAgy = new Button
            {
                Text = "Launch AGY CLI",
                Location = new Point(15, 26),
                Size = new Size(160, 36),
                Font = new Font("Segoe UI", 9f, FontStyle.Bold),
                UseVisualStyleBackColor = true
            };
            _btnLaunchAgy.Click += (s, e) => LaunchSession("agy");
            RegisterButton(_btnLaunchAgy, 
                "Starts an interactive Antigravity CLI session in a console window using only the portable USB environment.");

            _btnLaunchShell = new Button
            {
                Text = "Open Command Prompt",
                Location = new Point(187, 26),
                Size = new Size(160, 36),
                UseVisualStyleBackColor = true
            };
            _btnLaunchShell.Click += (s, e) => LaunchSession("cmd");
            RegisterButton(_btnLaunchShell, 
                "Opens a Command Prompt window pre-configured with the portable environment variables and 'agy' in the PATH.");

            _btnOpenData = new Button
            {
                Text = "Open Data Folder",
                Location = new Point(360, 26),
                Size = new Size(160, 36),
                UseVisualStyleBackColor = true
            };
            _btnOpenData.Click += BtnOpenData_Click;
            RegisterButton(_btnOpenData, 
                "Opens Windows Explorer to the USB data folder (where settings, skills, and token are stored).");

            _btnOpenConversations = new Button
            {
                Text = "View Conversations",
                Location = new Point(15, 74),
                Size = new Size(160, 32),
                UseVisualStyleBackColor = true
            };
            _btnOpenConversations.Click += BtnOpenConversations_Click;
            RegisterButton(_btnOpenConversations, 
                "Opens Windows Explorer to the folder containing your SQLite conversation databases and chat histories on the USB.");

            _btnRefresh = new Button
            {
                Text = "Refresh Status",
                Location = new Point(187, 74),
                Size = new Size(160, 32),
                UseVisualStyleBackColor = true
            };
            _btnRefresh.Click += (s, e) => RefreshStatus();
            RegisterButton(_btnRefresh, 
                "Re-scans the USB drive and the host PC to update the status indicators above.");

            _btnDownloadCore = new Button
            {
                Text = "Download CLI Binary",
                Location = new Point(360, 74),
                Size = new Size(160, 32),
                UseVisualStyleBackColor = true
            };
            _btnDownloadCore.Click += BtnDownloadCore_Click;
            RegisterButton(_btnDownloadCore, 
                "Downloads the official Google Antigravity CLI binary directly from Google servers or copies it from this PC.");

            gbLaunch.Controls.Add(_btnLaunchAgy);
            gbLaunch.Controls.Add(_btnLaunchShell);
            gbLaunch.Controls.Add(_btnOpenData);
            gbLaunch.Controls.Add(_btnOpenConversations);
            gbLaunch.Controls.Add(_btnRefresh);
            gbLaunch.Controls.Add(_btnDownloadCore);
            this.Controls.Add(gbLaunch);
        }

        private void RegisterButton(Button btn, string description)
        {
            btn.MouseEnter += (s, e) =>
            {
                _toolTip.Show(description, btn, 0, btn.Height + 4, 8000);
            };
            btn.MouseLeave += (s, e) =>
            {
                _toolTip.Hide(btn);
            };
            btn.Click += (s, e) =>
            {
                _toolTip.Hide(btn);
            };
        }

        private void RefreshStatus()
        {
            if (File.Exists(_coreExePath))
            {
                FileInfo fi = new FileInfo(_coreExePath);
                _lblCoreStatus.Text = string.Format("CLI Binary: Ready (bin\\agy.exe, {0:F1} MB)", fi.Length / (1024.0 * 1024.0));
                _lblCoreStatus.ForeColor = Color.DarkGreen;
                _btnLaunchAgy.Enabled = true;
                _btnLaunchShell.Enabled = true;
                _btnDownloadCore.Text = "Update CLI Binary";
            }
            else
            {
                _lblCoreStatus.Text = "CLI Binary: Not found (Click 'Download CLI Binary' below)";
                _lblCoreStatus.ForeColor = Color.Red;
                _btnLaunchAgy.Enabled = false;
                _btnLaunchShell.Enabled = false;
                _btnDownloadCore.Text = "Download CLI Binary";
            }

            if (File.Exists(_portableTokenPath))
            {
                FileInfo fi = new FileInfo(_portableTokenPath);
                _lblUsbAuthStatus.Text = string.Format("USB Login: Stored on USB (Modified: {0:g})", fi.LastWriteTime);
                _lblUsbAuthStatus.ForeColor = Color.DarkGreen;
                _btnClearUsb.Enabled = true;
                _btnExport.Enabled = true;
            }
            else
            {
                _lblUsbAuthStatus.Text = "USB Login: Not logged in (Click 'Import Host Login' or 'Sign In via Browser')";
                _lblUsbAuthStatus.ForeColor = SystemColors.GrayText;
                _btnClearUsb.Enabled = false;
                _btnExport.Enabled = false;
            }

            if (File.Exists(_hostTokenPath))
            {
                _lblHostAuthStatus.Text = "Host PC Login: Detected on this computer";
                _lblHostAuthStatus.ForeColor = Color.Navy;
                _btnImport.Enabled = true;
            }
            else
            {
                _lblHostAuthStatus.Text = "Host PC Login: No login found on this computer";
                _lblHostAuthStatus.ForeColor = SystemColors.GrayText;
                _btnImport.Enabled = false;
            }
        }

        private void BtnDownloadCore_Click(object sender, EventArgs e)
        {
            // If local host binary exists, offer instant copy
            if (File.Exists(_hostAgyExe))
            {
                DialogResult dr = MessageBox.Show(
                    "Found installed Google Antigravity binary on this PC at:\n" + _hostAgyExe + 
                    "\n\nWould you like to copy it from this PC (Instant)?\n\nClick 'Yes' to copy from PC, or 'No' to download fresh from Google.",
                    "Binary Source",
                    MessageBoxButtons.YesNoCancel,
                    MessageBoxIcon.Question);

                if (dr == DialogResult.Yes)
                {
                    try
                    {
                        if (!Directory.Exists(_binDir)) Directory.CreateDirectory(_binDir);
                        File.Copy(_hostAgyExe, _coreExePath, true);
                        RefreshStatus();
                        MessageBox.Show("Copied agy.exe into bin\\agy.exe successfully!", "Ready", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        return;
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Failed to copy from PC: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        return;
                    }
                }
                else if (dr == DialogResult.Cancel)
                {
                    return;
                }
            }

            // Download directly from Google servers
            StartDownloadFromGoogle();
        }

        private void StartDownloadFromGoogle()
        {
            try
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
                string manifestUrl = "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/windows_amd64.json";

                string downloadUrl = null;
                string version = "latest";

                using (WebClient manifestClient = new WebClient())
                {
                    manifestClient.Headers["User-Agent"] = "agy-portable/1.0";
                    string json = manifestClient.DownloadString(manifestUrl);
                    Match mUrl = Regex.Match(json, "\"url\"\\s*:\\s*\"([^\"]+)\"");
                    Match mVer = Regex.Match(json, "\"version\"\\s*:\\s*\"([^\"]+)\"");
                    if (mUrl.Success) downloadUrl = mUrl.Groups[1].Value;
                    if (mVer.Success) version = mVer.Groups[1].Value;
                }

                if (string.IsNullOrEmpty(downloadUrl))
                {
                    // Fallback to direct storage URL if manifest format differs
                    downloadUrl = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/windows-x64/cli_windows_x64.exe";
                }

                DialogResult confirm = MessageBox.Show(
                    string.Format("Download Antigravity CLI v{0} (~193 MB) from Google servers?\n\nURL: {1}", version, downloadUrl),
                    "Confirm Download",
                    MessageBoxButtons.OKCancel,
                    MessageBoxIcon.Information);

                if (confirm != DialogResult.OK) return;

                if (!Directory.Exists(_binDir)) Directory.CreateDirectory(_binDir);
                string tempTarget = _coreExePath + ".downloading";

                // Progress Dialog
                Form progressForm = new Form
                {
                    Text = "Downloading Antigravity CLI...",
                    ClientSize = new Size(420, 110),
                    FormBorderStyle = FormBorderStyle.FixedDialog,
                    StartPosition = FormStartPosition.CenterParent,
                    MaximizeBox = false,
                    MinimizeBox = false,
                    ControlBox = false
                };

                Label lblStatus = new Label
                {
                    Location = new Point(20, 15),
                    Size = new Size(380, 20),
                    Text = "Connecting to Google servers..."
                };

                ProgressBar pb = new ProgressBar
                {
                    Location = new Point(20, 42),
                    Size = new Size(380, 24),
                    Minimum = 0,
                    Maximum = 100,
                    Value = 0
                };

                progressForm.Controls.Add(lblStatus);
                progressForm.Controls.Add(pb);

                WebClient downloader = new WebClient();
                downloader.Headers["User-Agent"] = "agy-portable/1.0";

                downloader.DownloadProgressChanged += (s, pe) =>
                {
                    pb.Value = pe.ProgressPercentage;
                    lblStatus.Text = string.Format("Downloading: {0}% ({1:F1} MB / {2:F1} MB)",
                        pe.ProgressPercentage,
                        pe.BytesReceived / (1024.0 * 1024.0),
                        pe.TotalBytesToReceive / (1024.0 * 1024.0));
                };

                downloader.DownloadFileCompleted += (s, ce) =>
                {
                    progressForm.Close();
                    if (ce.Error != null)
                    {
                        if (File.Exists(tempTarget)) File.Delete(tempTarget);
                        MessageBox.Show("Download failed: " + ce.Error.Message, "Download Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                    else
                    {
                        if (File.Exists(_coreExePath)) File.Delete(_coreExePath);
                        File.Move(tempTarget, _coreExePath);
                        RefreshStatus();
                        MessageBox.Show("Antigravity CLI v" + version + " downloaded successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    downloader.Dispose();
                };

                downloader.DownloadFileAsync(new Uri(downloadUrl), tempTarget);
                progressForm.ShowDialog(this);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Unable to initiate download: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnImport_Click(object sender, EventArgs e)
        {
            try
            {
                if (!File.Exists(_hostTokenPath))
                {
                    MessageBox.Show("No existing login token was found on this PC at:\n" + _hostTokenPath, "Token Not Found", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                string portableGeminiDir = Path.GetDirectoryName(_portableTokenPath);
                if (!Directory.Exists(portableGeminiDir))
                {
                    Directory.CreateDirectory(portableGeminiDir);
                }

                File.Copy(_hostTokenPath, _portableTokenPath, true);
                RefreshStatus();
                MessageBox.Show("Login credentials successfully copied to your USB drive.\n\nYou can now run AGY portably on any PC with this login.", "Login Imported", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to import credentials: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnExport_Click(object sender, EventArgs e)
        {
            try
            {
                if (!File.Exists(_portableTokenPath))
                {
                    MessageBox.Show("No login token found on USB to export.", "Notice", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                DialogResult dr = MessageBox.Show("This will overwrite the Antigravity login token on this host PC with the token from your USB drive.\n\nDo you want to proceed?", "Confirm Export", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                if (dr != DialogResult.Yes) return;

                if (!Directory.Exists(_hostGeminiDir))
                {
                    Directory.CreateDirectory(_hostGeminiDir);
                }

                File.Copy(_portableTokenPath, _hostTokenPath, true);
                RefreshStatus();
                MessageBox.Show("Successfully exported USB credentials to this PC.", "Export Complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to export credentials: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnClearUsb_Click(object sender, EventArgs e)
        {
            try
            {
                if (!File.Exists(_portableTokenPath)) return;

                DialogResult dr = MessageBox.Show("Are you sure you want to remove your login credentials from this USB drive?\n\n(Your conversations, settings, and skills will remain safe.)", "Confirm Remove", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                if (dr == DialogResult.Yes)
                {
                    File.Delete(_portableTokenPath);
                    RefreshStatus();
                    MessageBox.Show("USB login credentials removed.", "Removed", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to delete token: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnSignIn_Click(object sender, EventArgs e)
        {
            LaunchSession("auth");
        }

        private void BtnOpenData_Click(object sender, EventArgs e)
        {
            try
            {
                string target = Path.Combine(_portableHomeDir, ".gemini");
                if (!Directory.Exists(target)) Directory.CreateDirectory(target);
                Process.Start("explorer.exe", target);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Unable to open folder: " + ex.Message);
            }
        }

        private void BtnOpenConversations_Click(object sender, EventArgs e)
        {
            try
            {
                string target = Path.Combine(_portableHomeDir, ".gemini", "antigravity-cli", "conversations");
                if (!Directory.Exists(target)) Directory.CreateDirectory(target);
                Process.Start("explorer.exe", target);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Unable to open folder: " + ex.Message);
            }
        }

        private void LaunchSession(string mode)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.WorkingDirectory = _appDir;
                psi.UseShellExecute = false;

                // Configure Isolated Portable Environment
                psi.EnvironmentVariables["PORTABLE_ROOT"] = _appDir;
                psi.EnvironmentVariables["USERPROFILE"] = _portableHomeDir;
                psi.EnvironmentVariables["HOME"] = _portableHomeDir;
                psi.EnvironmentVariables["HOMEDRIVE"] = _dataRoot.Substring(0, 2);
                psi.EnvironmentVariables["HOMEPATH"] = _portableHomeDir.Substring(2);
                psi.EnvironmentVariables["APPDATA"] = Path.Combine(_dataRoot, "AppData", "Roaming");
                psi.EnvironmentVariables["LOCALAPPDATA"] = Path.Combine(_dataRoot, "AppData", "Local");
                psi.EnvironmentVariables["PATH"] = Path.Combine(_appDir, "bin") + ";" + _appDir + ";" + Environment.GetEnvironmentVariable("PATH");

                if (mode == "agy")
                {
                    psi.FileName = "cmd.exe";
                    psi.Arguments = "/c title AGY Portable && \"" + _coreExePath + "\"";
                }
                else if (mode == "auth")
                {
                    psi.FileName = "cmd.exe";
                    psi.Arguments = "/c title AGY Authentication && echo Initiating Google OAuth Login... && \"" + _coreExePath + "\" && pause";
                }
                else // cmd shell
                {
                    psi.FileName = "cmd.exe";
                    psi.Arguments = "/k \"" + Path.Combine(_appDir, "agy-shell.cmd") + "\"";
                }

                Process proc = Process.Start(psi);
                if (mode == "auth" && proc != null)
                {
                    proc.EnableRaisingEvents = true;
                    proc.Exited += (s, ev) =>
                    {
                        if (this.InvokeRequired)
                        {
                            this.Invoke(new Action(RefreshStatus));
                        }
                        else
                        {
                            RefreshStatus();
                        }
                    };
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to launch session: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
