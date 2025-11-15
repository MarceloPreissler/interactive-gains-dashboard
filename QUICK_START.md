# Quick Start Guide - 3 Simple Steps

## Step 1: Run Diagnostic (Find Issues)

Open **Command Prompt** in this folder and run:

```bash
diagnose.bat
```

This will check what's missing and tell you exactly what to fix.

## Step 2: Fix Issues

### If Python is missing:
Download and install from: https://www.python.org/downloads/
**IMPORTANT:** Check ✅ "Add Python to PATH" during installation

### If Git is missing:
Download and install from: https://git-scm.com/download/win

### If ODBC Driver is missing:
Download and install from: https://go.microsoft.com/fwlink/?linkid=2249004

### If Python packages are missing:
```bash
pip install -r requirements.txt
```

## Step 3: Test It Works

Run the batch file:

```bash
run_daily_refresh.bat
```

If you see "SUCCESS!" - you're done!

## What Each File Does

| File | Purpose |
|------|---------|
| `diagnose.bat` | Checks if everything is installed correctly |
| `run_daily_refresh.bat` | Runs the data fetch (use this!) |
| `setup_environment.bat` | Auto-installs Python/Git (requires admin) |
| `LOCAL_SETUP.md` | Full documentation for Task Scheduler setup |

## After Testing Works

Follow `LOCAL_SETUP.md` to set up automatic daily execution at 7 AM.

## Troubleshooting

**"Python not found"**
- Install Python from link above
- Restart Command Prompt after installing

**"pyodbc not installed"**
- Run: `pip install -r requirements.txt`

**"ODBC Driver not found"**
- Install from link above

**"Database connection failed"**
- Check if SQL Server is running
- Verify you can connect from SQL Server Management Studio
- Check credentials in `run_daily_refresh.bat`

## Need Help?

1. Run `diagnose.bat` - it will tell you exactly what's wrong
2. Fix the issues it identifies
3. Run `run_daily_refresh.bat` again

That's it!
