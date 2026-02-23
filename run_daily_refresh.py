#!/usr/bin/env python3
"""
Daily Data Refresh - Local Runner
Fetches SQL data, commits, and pushes to GitHub.
Designed to run via Windows Task Scheduler (non-interactive).
Log: D:\TXU_Reporting\Logs\Dashboard_Refresh.log
"""

import os
import sys
import subprocess
from datetime import datetime

# -- Configuration --
REPO_DIR = r"D:\TXU\__Git\Interactive-Gains-Dashboard"
TOKEN_FILE = r"D:\TXU\__Git\.gh_token"
LOG_FILE = r"D:\TXU_Reporting\Logs\Dashboard_Refresh.log"
PYTHON_EXE = r"D:\Python311\python.exe"
REMOTE_URL = "https://{}@github.com/MarceloPreissler/interactive-gains-dashboard.git"

# DB credentials
DB_ENV = {
    "DB_SERVER": r"FTHYN54\MSSQLSERVER2",
    "DB_DATABASE": "Skywalker",
    "DB_USERNAME": "mpreissler",
    "DB_PASSWORD": "Gremio.84",
}


def log(msg, logfile=None):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    if logfile:
        logfile.write(line + "\n")
        logfile.flush()


def run_cmd(cmd, cwd=None, env=None, logfile=None):
    """Run a command, log output, return (success, output)."""
    result = subprocess.run(
        cmd, capture_output=True, text=True, timeout=300, cwd=cwd, env=env
    )
    output = (result.stdout + result.stderr).strip()
    if output and logfile:
        logfile.write(output + "\n")
        logfile.flush()
    return result.returncode == 0, output, result.returncode


def main():
    os.chdir(REPO_DIR)

    with open(LOG_FILE, "a", encoding="utf-8") as lf:
        log("=" * 50, lf)
        log("TXU Dashboard - Daily Data Refresh", lf)
        log("=" * 50, lf)

        # -- Read GitHub token --
        if not os.path.exists(TOKEN_FILE):
            log(f"ERROR: Token file not found: {TOKEN_FILE}", lf)
            return 1
        with open(TOKEN_FILE) as f:
            gh_token = f.read().strip()
        if not gh_token:
            log("ERROR: Token file is empty", lf)
            return 1
        log(f"GitHub token loaded ({len(gh_token)} chars)", lf)

        # -- Step 1: Fetch data --
        log("[1/3] Fetching data from SQL Server...", lf)
        env = {**os.environ, **DB_ENV}
        ok, output, rc = run_cmd(
            [PYTHON_EXE, "fetch_data.py"], cwd=REPO_DIR, env=env, logfile=lf
        )
        if not ok:
            log(f"ERROR: Data fetch failed (exit {rc})", lf)
            return 1
        log("[1/3] Data fetch complete", lf)

        # -- Step 2: Stage and commit --
        log("[2/3] Checking for changes...", lf)
        run_cmd(["git", "add", "data/dashboard_data.csv"], cwd=REPO_DIR, logfile=lf)

        ok, _, _ = run_cmd(["git", "diff", "--staged", "--quiet"], cwd=REPO_DIR)
        if ok:
            log("No changes to commit - data is unchanged", lf)
            log("SUCCESS - No update needed", lf)
            log("", lf)
            return 0

        today = datetime.now().strftime("%Y-%m-%d")
        ok, output, rc = run_cmd(
            ["git", "commit", "-m", f"Auto-update dashboard data - {today}"],
            cwd=REPO_DIR, logfile=lf,
        )
        if not ok:
            log(f"ERROR: Git commit failed (exit {rc})", lf)
            return 1
        log("[2/3] Committed", lf)

        # -- Step 3: Push using token --
        log("[3/3] Pushing to GitHub...", lf)
        push_url = REMOTE_URL.format(gh_token)
        ok, output, rc = run_cmd(
            ["git", "-c", "credential.helper=", "push", push_url, "main"],
            cwd=REPO_DIR, logfile=lf,
        )
        if not ok:
            log(f"ERROR: Git push failed (exit {rc})", lf)
            # Don't log push output to avoid leaking token in error messages
            return 1
        # Update tracking ref so origin/main stays in sync
        run_cmd(
            ["git", "update-ref", "refs/remotes/origin/main", "HEAD"],
            cwd=REPO_DIR,
        )
        log("[3/3] Pushed to GitHub", lf)

        log("SUCCESS - Dashboard data updated", lf)
        log("", lf)
        return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        # Emergency log
        with open(LOG_FILE, "a") as lf:
            log(f"FATAL: {e}", lf)
        sys.exit(1)
