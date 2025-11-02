# Local Automation Setup - Windows Task Scheduler

Since your SQL Server (`FTHYN54\MSSQLSERVER2`) is on an internal network that GitHub Actions cannot reach, we'll run the automation **locally on your machine** using Windows Task Scheduler.

## Overview

The script will:
1. Connect to your SQL Server database
2. Execute the query and generate CSV
3. Commit the CSV to Git
4. Push to GitHub automatically

This runs at 7:00 AM daily on your local machine.

## Prerequisites

### 1. Install Python (if not already installed)

Download and install Python 3.11+ from: https://www.python.org/downloads/

**Important:** During installation, check ✅ **"Add Python to PATH"**

### 2. Install Python Dependencies

Open **Command Prompt** or **PowerShell** and navigate to your repository folder:

```bash
cd path\to\interactive-gains-dashboard
pip install -r requirements.txt
```

### 3. Install ODBC Driver (if not already installed)

Download and install **ODBC Driver 18 for SQL Server**:
https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server

Choose: **ODBC Driver 18 for SQL Server (x64)**

### 4. Configure Git Credentials

Make sure Git can push without prompting for password. Use one of these methods:

**Option A: Credential Manager (Recommended)**
```bash
git config --global credential.helper manager-core
```
Push once manually - Windows will save your credentials.

**Option B: Personal Access Token**
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` permissions
3. Use token as password when pushing

## Setup Instructions

### Step 1: Test the Script Manually

1. Open **Command Prompt** or **PowerShell** as Administrator
2. Navigate to your repository:
   ```bash
   cd C:\path\to\interactive-gains-dashboard
   ```

3. Run the batch script:
   ```bash
   run_daily_refresh.bat
   ```

   OR run the PowerShell script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File run_daily_refresh.ps1
   ```

4. **Verify it works:**
   - Check for `data/dashboard_data.csv` file
   - Check GitHub for new commit
   - Check dashboard displays the data

### Step 2: Create Scheduled Task

#### Using Task Scheduler GUI:

1. **Open Task Scheduler:**
   - Press `Win + R`
   - Type `taskschd.msc` and press Enter

2. **Create New Task:**
   - Click **"Create Task"** (not "Create Basic Task")
   - Name: `TXU Dashboard Data Refresh`
   - Description: `Daily data refresh for TXU Mass Portfolio Gains Dashboard`
   - Select: ☑ **"Run whether user is logged on or not"**
   - Select: ☑ **"Run with highest privileges"**
   - Configure for: **Windows 10**

3. **Triggers Tab:**
   - Click **"New..."**
   - Begin the task: **On a schedule**
   - Settings: **Daily**
   - Start: **7:00:00 AM**
   - Recur every: **1 days**
   - Enabled: ☑ **Yes**
   - Click **OK**

4. **Actions Tab:**
   - Click **"New..."**
   - Action: **Start a program**

   **For Batch Script:**
   - Program/script: `cmd.exe`
   - Add arguments: `/c "C:\full\path\to\interactive-gains-dashboard\run_daily_refresh.bat"`
   - Start in: `C:\full\path\to\interactive-gains-dashboard`

   **OR for PowerShell Script:**
   - Program/script: `powershell.exe`
   - Add arguments: `-ExecutionPolicy Bypass -File "C:\full\path\to\interactive-gains-dashboard\run_daily_refresh.ps1"`
   - Start in: `C:\full\path\to\interactive-gains-dashboard`

   - Click **OK**

5. **Conditions Tab:**
   - Uncheck: ☐ **"Start the task only if the computer is on AC power"**
   - Check: ☑ **"Wake the computer to run this task"** (optional)

6. **Settings Tab:**
   - Check: ☑ **"Allow task to be run on demand"**
   - Check: ☑ **"Run task as soon as possible after a scheduled start is missed"**
   - If the task fails, restart every: **10 minutes** (optional)

7. **Click OK** and enter your Windows password when prompted

#### Using PowerShell (Alternative):

Run this PowerShell command as Administrator (replace paths):

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"C:\full\path\to\interactive-gains-dashboard\run_daily_refresh.ps1`"" -WorkingDirectory "C:\full\path\to\interactive-gains-dashboard"

$trigger = New-ScheduledTaskTrigger -Daily -At 7:00AM

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType ServiceAccount -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "TXU Dashboard Data Refresh" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Daily data refresh for TXU Mass Portfolio Gains Dashboard"
```

### Step 3: Test the Scheduled Task

1. Open **Task Scheduler**
2. Find **"TXU Dashboard Data Refresh"** in the task list
3. Right-click → **"Run"**
4. Check **"Last Run Result"** should show **"The operation completed successfully (0x0)"**
5. Verify new commit on GitHub

## Troubleshooting

### Script Fails to Run

**Check Python is in PATH:**
```bash
python --version
```
Should show Python 3.11 or higher.

**Check Git is in PATH:**
```bash
git --version
```

### Database Connection Fails

- Verify you can connect to `FTHYN54\MSSQLSERVER2` from your machine
- Check credentials in the script are correct
- Ensure ODBC Driver 18 is installed

### Git Push Fails

- Run `git push` manually once to cache credentials
- Check network connectivity
- Verify GitHub credentials are valid

### Task Scheduler Shows Error

**View detailed error:**
1. Task Scheduler → Right-click task → **Properties**
2. **History** tab → Review error messages

**Common fixes:**
- Use full absolute paths (not relative)
- Run as Administrator
- Check "Run whether user is logged on or not"
- Verify working directory is set correctly

## Viewing Logs

**Task Scheduler History:**
1. Open Task Scheduler
2. Find your task
3. Click **History** tab at the bottom
4. Review execution history and errors

**Script Output (Optional):**

To save script output to a log file, modify the scheduled task action:

**Batch file:**
```
cmd /c "C:\path\to\run_daily_refresh.bat >> C:\path\to\logs\refresh.log 2>&1"
```

**PowerShell:**
```
powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\run_daily_refresh.ps1" >> "C:\path\to\logs\refresh.log" 2>&1
```

## Security Note

The scripts contain your database password in plain text. To secure them:

1. **File Permissions:** Right-click script → Properties → Security → Only allow your user account to read
2. **Environment Variables:** Store credentials in Windows environment variables instead
3. **Windows Credential Manager:** Use secure credential storage (advanced)

## Alternative: Manual Execution

If you prefer to run manually instead of scheduled:

1. Double-click `run_daily_refresh.bat`
2. Review output
3. Data is refreshed and pushed to GitHub

## Disabling GitHub Actions (Optional)

Since we're using local automation now, you can disable the GitHub Actions workflow:

1. Go to: `.github/workflows/daily-data-refresh.yml`
2. Delete the file, OR
3. Rename it to `daily-data-refresh.yml.disabled`

This prevents unnecessary failed runs in GitHub Actions.

## Support

If you encounter issues:
1. Test the Python script manually: `python fetch_data.py`
2. Check Task Scheduler history for error details
3. Verify all prerequisites are installed
4. Ensure paths in Task Scheduler are absolute, not relative
