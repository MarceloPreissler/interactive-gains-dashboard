# Daily Data Refresh Script for TXU Dashboard
# This PowerShell script runs the Python data fetch and auto-commits to GitHub

param(
    [string]$Server = "FTHYN54\MSSQLSERVER2",
    [string]$Database = "Skywalker",
    [string]$Username = "mpreissler",
    [string]$Password = "Gremio.84"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TXU Dashboard - Daily Data Refresh" -ForegroundColor Cyan
Write-Host "Started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Navigate to script directory
    Set-Location $PSScriptRoot

    # Set environment variables
    $env:DB_SERVER = $Server
    $env:DB_DATABASE = $Database
    $env:DB_USERNAME = $Username
    $env:DB_PASSWORD = $Password

    # Run Python script
    Write-Host "[1/3] Fetching data from SQL Server..." -ForegroundColor Yellow
    python fetch_data.py
    if ($LASTEXITCODE -ne 0) {
        throw "Data fetch failed with exit code $LASTEXITCODE"
    }

    Write-Host ""
    Write-Host "[2/3] Committing changes to Git..." -ForegroundColor Yellow
    git add data/dashboard_data.csv

    # Check if there are changes to commit
    git diff --staged --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "No changes to commit - data is unchanged." -ForegroundColor Gray
    } else {
        $commitMessage = "Auto-update dashboard data - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git commit -m $commitMessage
        if ($LASTEXITCODE -ne 0) {
            throw "Git commit failed with exit code $LASTEXITCODE"
        }
    }

    Write-Host ""
    Write-Host "[3/3] Pushing to GitHub..." -ForegroundColor Yellow
    git push
    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed with exit code $LASTEXITCODE"
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS! Dashboard data updated." -ForegroundColor Green
    Write-Host "Completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

    exit 0
}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}
