@echo off
REM Daily Data Refresh Script for TXU Dashboard
REM Runs locally via scheduled task, fetches SQL data, commits + pushes to GitHub
REM Log: D:\TXU_Reporting\Logs\Dashboard_Refresh.log

setlocal enabledelayedexpansion

REM -- Logging Setup --
set LOGFILE=D:\TXU_Reporting\Logs\Dashboard_Refresh.log
echo ======================================== >> "%LOGFILE%"
echo TXU Dashboard - Daily Data Refresh >> "%LOGFILE%"
echo Started at %date% %time% >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"

REM Navigate to the repository directory
cd /d "D:\TXU\__Git\Interactive-Gains-Dashboard"

REM -- Database Credentials --
set DB_SERVER=FTHYN54\MSSQLSERVER2
set DB_DATABASE=Skywalker
set DB_USERNAME=mpreissler
set DB_PASSWORD=Gremio.84

REM -- GitHub Auth: read token from external file (not in git) --
set GH_TOKEN_FILE=D:\TXU\__Git\.gh_token
if not exist "%GH_TOKEN_FILE%" (
    echo ERROR: GitHub token file not found at %GH_TOKEN_FILE% >> "%LOGFILE%"
    exit /b 1
)
set /p GH_TOKEN=<"%GH_TOKEN_FILE%"
set GIT_TERMINAL_PROMPT=0

REM -- Step 1: Fetch data from SQL Server --
echo [1/3] Fetching data from SQL Server... >> "%LOGFILE%"
D:\Python311\python.exe fetch_data.py >> "%LOGFILE%" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Data fetch failed! >> "%LOGFILE%"
    exit /b 1
)

REM -- Step 2: Stage and commit --
echo [2/3] Committing changes to Git... >> "%LOGFILE%"
git add data/dashboard_data.csv
git diff --staged --quiet
if %ERRORLEVEL% EQU 0 (
    echo No changes to commit - data is unchanged. >> "%LOGFILE%"
) else (
    git commit -m "Auto-update dashboard data - %date:~-4%-%date:~4,2%-%date:~7,2%" >> "%LOGFILE%" 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Git commit failed! >> "%LOGFILE%"
        exit /b 1
    )
)

REM -- Step 3: Push to GitHub using token auth --
echo [3/3] Pushing to GitHub... >> "%LOGFILE%"
git -c credential.helper= -c http.extraHeader="Authorization: bearer !GH_TOKEN!" push >> "%LOGFILE%" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git push failed! >> "%LOGFILE%"
    exit /b 1
)

echo SUCCESS - Dashboard data updated at %date% %time% >> "%LOGFILE%"
echo. >> "%LOGFILE%"

endlocal
exit /b 0
