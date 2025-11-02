# TXU Mass Portfolio Gains Dashboard - Automated Setup Guide

## Overview

This dashboard automatically fetches data from your SQL Server database daily at 7:00 AM Central Time and displays interactive metrics on gains, plan, and losses across various dimensions.

## Architecture

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  SQL Server     │─────▶│  GitHub Actions  │─────▶│  data/          │
│  (Skywalker DB) │      │  (Daily at 7AM)  │      │  dashboard_data │
└─────────────────┘      └──────────────────┘      └─────────────────┘
                                                              │
                                                              ▼
                                                    ┌─────────────────┐
                                                    │  Dashboard      │
                                                    │  (Auto-loads)   │
                                                    └─────────────────┘
```

## Setup Instructions

### 1. Configure Database Secrets

You need to add the following secrets to your GitHub repository:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add each of the following:

| Secret Name | Description | Example |
|------------|-------------|---------|
| `DB_SERVER` | SQL Server address | `your-server.database.windows.net` |
| `DB_DATABASE` | Database name | `Skywalker` |
| `DB_USERNAME` | Database username | `your-username` |
| `DB_PASSWORD` | Database password | `your-password` |

### 2. Enable GitHub Actions

1. Go to **Actions** tab in your repository
2. Enable workflows if prompted
3. The workflow will run automatically every day at 7:00 AM CT
4. You can also manually trigger it by:
   - Going to **Actions** → **Daily Data Refresh**
   - Click **Run workflow**

### 3. Verify Setup

After the first run (or manual trigger):

1. Check the **Actions** tab to see if the workflow ran successfully
2. Verify that `data/dashboard_data.csv` was created/updated
3. Open `index.html` in your browser to see the dashboard with auto-loaded data

## Files Overview

### Core Files

- **`fetch_data.py`** - Python script that connects to SQL Server and generates CSV
- **`requirements.txt`** - Python dependencies (pyodbc, pandas)
- **`.github/workflows/daily-data-refresh.yml`** - GitHub Actions workflow for automation
- **`index.html`** - Main dashboard HTML
- **`script.js`** - Dashboard JavaScript (includes auto-load functionality)
- **`data/dashboard_data.csv`** - Generated data file (auto-updated daily)

### How It Works

1. **Daily Execution**: GitHub Actions runs `fetch_data.py` at 7:00 AM CT
2. **Data Fetch**: Script connects to SQL Server, executes the query, and generates CSV
3. **Auto-Commit**: Workflow commits the new CSV to the repository
4. **Auto-Load**: When you open the dashboard, it automatically fetches and displays the latest data

## Manual Usage

You can still manually upload files to the dashboard:

1. Open `index.html`
2. Click the upload area or drag-and-drop a CSV/Excel file
3. Dashboard will update with the uploaded data

## Data Format

The CSV contains the following columns:

- `year` - Year (YYYY)
- `month` - Month (MM)
- `channel` - Sales channel (Call Center, Web Search, SOE, RAQ, BAAT, DM, Other)
- `meter_type` - Meter type (RES, BUS)
- `product_group` - Product group (MTM, TERM)
- `gains` - Actual gains
- `plan` - Planned gains
- `losses` - Actual losses

## SQL Query

The query fetches data from `Skywalker.dbo.Mass_Plan_Proj_Actual` starting from January 2024 through the current month, aggregating by:
- Channel (with standardized groupings)
- Meter type (RES/BUS)
- Product group (MTM/TERM)

## Timezone Configuration

The workflow is currently set for **7:00 AM CDT (UTC-5)**. To adjust:

1. Edit `.github/workflows/daily-data-refresh.yml`
2. Modify the cron schedule:
   - `0 13 * * *` = 7:00 AM CDT (UTC-5)
   - `0 12 * * *` = 7:00 AM CST (UTC-6)

## Troubleshooting

### Workflow Fails

1. Check **Actions** tab for error details
2. Verify database secrets are correctly configured
3. Ensure database allows connections from GitHub Actions IPs
4. Check `fetch_data.py` logs for specific errors

### Dashboard Shows "No data file found"

1. Verify `data/dashboard_data.csv` exists in the repository
2. Check if the workflow has run successfully
3. Try manually triggering the workflow
4. As a fallback, manually upload a CSV file

### Database Connection Issues

- Ensure firewall rules allow GitHub Actions IPs
- Verify credentials are correct
- Check if ODBC Driver 17 is compatible with your SQL Server version

## Development

To run the data fetch script locally:

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DB_SERVER="your-server"
export DB_DATABASE="Skywalker"
export DB_USERNAME="your-username"
export DB_PASSWORD="your-password"

# Run script
python fetch_data.py
```

## Support

For issues or questions:
1. Check the GitHub Actions logs for detailed error messages
2. Review the SQL query output for data validation
3. Ensure database permissions are correctly configured
