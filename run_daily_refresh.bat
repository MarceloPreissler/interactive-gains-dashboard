@echo off
REM Daily Data Refresh Script for TXU Dashboard
REM This script runs the Python data fetch and auto-commits to GitHub

echo ========================================
echo TXU Dashboard - Daily Data Refresh
echo Started at %date% %time%
echo ========================================
echo.

REM Navigate to the repository directory
cd /d "%~dp0"

REM Set database credentials as environment variables
REM IMPORTANT: Replace these with your actual credentials
set DB_SERVER=FTHYN54\MSSQLSERVER2
set DB_DATABASE=Skywalker
set DB_USERNAME=mpreissler
set DB_PASSWORD=Gremio.84

REM Run the Python script
echo [1/3] Fetching data from SQL Server...
D:\Python311\python.exe fetch_data.py
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Data fetch failed!
    echo Check the error message above.
    exit /b 1
)

echo.
echo [2/3] Committing changes to Git...
git add data/dashboard_data.csv
git diff --staged --quiet
if %ERRORLEVEL% EQU 0 (
    echo No changes to commit - data is unchanged.
) else (
    git commit -m "Auto-update dashboard data - %date% %time%"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Git commit failed!
        exit /b 1
    )
)

echo.
echo [3/3] Pushing to GitHub...
git push
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git push failed!
    echo Check your network connection and GitHub credentials.
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! Dashboard data updated.
echo Completed at %date% %time%
echo ========================================

REM Uncomment the line below if you want to see the output when running manually
REM pause
