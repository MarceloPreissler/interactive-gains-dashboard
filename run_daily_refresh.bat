@echo off
REM Daily Data Refresh - Wrapper for Task Scheduler
REM Calls Python script which handles data fetch, git commit, and push
D:\Python311\python.exe "D:\TXU\__Git\Interactive-Gains-Dashboard\run_daily_refresh.py"
exit /b %ERRORLEVEL%
