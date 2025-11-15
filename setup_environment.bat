@echo off
echo ========================================
echo TXU Dashboard - Automatic Setup
echo ========================================
echo.
echo This script will automatically install and configure everything needed.
echo.
pause

REM Check if running as administrator
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [Step 1/4] Installing Chocolatey package manager...
echo.

REM Check if Chocolatey is installed
where choco >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

    REM Refresh environment variables
    call refreshenv
) else (
    echo Chocolatey already installed
)
echo.

echo [Step 2/4] Installing Python and Git...
echo.

REM Install Python if not present
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Installing Python...
    choco install python -y
    call refreshenv
) else (
    echo Python already installed
)

REM Install Git if not present
git --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Installing Git...
    choco install git -y
    call refreshenv
) else (
    echo Git already installed
)
echo.

echo [Step 3/4] Installing Python packages...
echo.
pip install --upgrade pip
pip install -r requirements.txt
echo.

echo [Step 4/4] Checking ODBC Driver...
echo.

reg query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Driver 18 for SQL Server" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    reg query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Driver 17 for SQL Server" >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo ODBC Driver not found. Opening download page...
        echo Please download and install ODBC Driver 18 for SQL Server
        echo After installation, run this script again.
        start https://go.microsoft.com/fwlink/?linkid=2249004
        pause
        exit /b 1
    ) else (
        echo ODBC Driver 17 found
    )
) else (
    echo ODBC Driver 18 found
)
echo.

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Run: diagnose.bat (to verify everything works)
echo 2. Run: run_daily_refresh.bat (to test data fetch)
echo 3. Set up Task Scheduler (see LOCAL_SETUP.md)
echo.
pause
