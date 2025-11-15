@echo off
echo ========================================
echo TXU Dashboard - System Diagnostics
echo ========================================
echo.

echo Checking prerequisites...
echo.

REM Check 1: Python
echo [1/6] Checking Python installation...
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Python is NOT installed or not in PATH
    echo        Download from: https://www.python.org/downloads/
    echo        IMPORTANT: Check "Add Python to PATH" during installation
    set PYTHON_OK=0
) else (
    python --version
    echo [OK] Python is installed
    set PYTHON_OK=1
)
echo.

REM Check 2: Git
echo [2/6] Checking Git installation...
git --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Git is NOT installed or not in PATH
    echo        Download from: https://git-scm.com/download/win
    set GIT_OK=0
) else (
    git --version
    echo [OK] Git is installed
    set GIT_OK=1
)
echo.

REM Check 3: Python packages
echo [3/6] Checking Python packages...
if %PYTHON_OK%==1 (
    python -c "import pyodbc" >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [FAIL] pyodbc is NOT installed
        echo        Run: pip install -r requirements.txt
        set PYODBC_OK=0
    ) else (
        echo [OK] pyodbc is installed
        set PYODBC_OK=1
    )

    python -c "import pandas" >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [FAIL] pandas is NOT installed
        echo        Run: pip install -r requirements.txt
        set PANDAS_OK=0
    ) else (
        echo [OK] pandas is installed
        set PANDAS_OK=1
    )
) else (
    echo [SKIP] Cannot check packages - Python not available
    set PYODBC_OK=0
    set PANDAS_OK=0
)
echo.

REM Check 4: ODBC Driver
echo [4/6] Checking ODBC Driver for SQL Server...
reg query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Driver 17 for SQL Server" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] ODBC Driver 17 for SQL Server is installed
    set ODBC_OK=1
    goto :odbc_done
)

reg query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Driver 18 for SQL Server" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] ODBC Driver 18 for SQL Server is installed
    set ODBC_OK=1
    goto :odbc_done
)

reg query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Driver 13 for SQL Server" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] ODBC Driver 13 for SQL Server is installed
    set ODBC_OK=1
    goto :odbc_done
)

echo [FAIL] No ODBC Driver for SQL Server found
echo        Download from: https://go.microsoft.com/fwlink/?linkid=2249004
set ODBC_OK=0

:odbc_done
echo.

REM Check 5: Required files
echo [5/6] Checking required files...
if exist "fetch_data.py" (
    echo [OK] fetch_data.py exists
    set FETCH_OK=1
) else (
    echo [FAIL] fetch_data.py NOT found
    echo        Run: git pull origin main
    set FETCH_OK=0
)

if exist "requirements.txt" (
    echo [OK] requirements.txt exists
) else (
    echo [FAIL] requirements.txt NOT found
    echo        Run: git pull origin main
)
echo.

REM Check 6: Database connectivity (if all prerequisites are OK)
echo [6/6] Checking database connectivity...
if %PYTHON_OK%==1 if %PYODBC_OK%==1 if %ODBC_OK%==1 if %FETCH_OK%==1 (
    echo Testing connection to FTHYN54\MSSQLSERVER2...

    set DB_SERVER=FTHYN54\MSSQLSERVER2
    set DB_DATABASE=Skywalker
    set DB_USERNAME=mpreissler
    set DB_PASSWORD=Gremio.84

    python -c "import pyodbc; pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER=FTHYN54\MSSQLSERVER2;DATABASE=Skywalker;UID=mpreissler;PWD=Gremio.84;TrustServerCertificate=yes;Timeout=5')" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Database connection successful
        set DB_OK=1
    ) else (
        python -c "import pyodbc; pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=FTHYN54\MSSQLSERVER2;DATABASE=Skywalker;UID=mpreissler;PWD=Gremio.84;Timeout=5')" >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo [OK] Database connection successful (Driver 17)
            set DB_OK=1
        ) else (
            echo [FAIL] Cannot connect to database
            echo        Possible reasons:
            echo        - SQL Server not accessible from this machine
            echo        - Incorrect credentials
            echo        - Firewall blocking connection
            echo        - SQL Server service not running
            set DB_OK=0
        )
    )
) else (
    echo [SKIP] Cannot test database - prerequisites not met
    set DB_OK=0
)
echo.

REM Summary
echo ========================================
echo DIAGNOSTIC SUMMARY
echo ========================================
if %PYTHON_OK%==1 if %GIT_OK%==1 if %PYODBC_OK%==1 if %PANDAS_OK%==1 if %ODBC_OK%==1 if %FETCH_OK%==1 if %DB_OK%==1 (
    echo [SUCCESS] All checks passed! System is ready.
    echo.
    echo You can now run: run_daily_refresh.bat
    echo.
) else (
    echo [ATTENTION] Some issues found. Please fix:
    echo.
    if %PYTHON_OK%==0 echo - Install Python from https://www.python.org/downloads/
    if %GIT_OK%==0 echo - Install Git from https://git-scm.com/download/win
    if %PYODBC_OK%==0 echo - Run: pip install pyodbc
    if %PANDAS_OK%==0 echo - Run: pip install pandas
    if %ODBC_OK%==0 echo - Install ODBC Driver from https://go.microsoft.com/fwlink/?linkid=2249004
    if %FETCH_OK%==0 echo - Run: git pull origin main
    if %DB_OK%==0 echo - Check database connectivity and credentials
    echo.
)

echo ========================================
echo.
echo Press any key to close...
pause >nul
