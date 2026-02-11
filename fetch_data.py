#!/usr/bin/env python3
"""
SQL Query Executor for TXU Mass Portfolio Gains Dashboard
Runs daily to fetch latest data and generate CSV for dashboard consumption
"""

import os
import sys
import pyodbc
import pandas as pd
from datetime import datetime

# SQL Query
SQL_QUERY = """
SELECT LEFT(p.YEARMONTH,4) AS year
      ,RIGHT(p.YEARMONTH,2) AS month
      ,CASE WHEN p.CHANNEL IN ('REACTIVE','WEB PHONE REACTIVE','CALL CENTER') THEN 'Call Center'
            WHEN p.CHANNEL IN ('WEB SEARCH','WEB_SEARCH','EMAIL/RAF') THEN 'Web Search'
            WHEN p.CHANNEL IN ('ONLINE PARTNER') THEN 'SOE'
            WHEN p.CHANNEL IN ('RAQ','REQUEST A QUOTE') THEN 'RAQ'
            WHEN p.CHANNEL IN ('BAAT','OBTM','OUTBOUND') THEN 'BAAT'
            WHEN p.CHANNEL IN ('DIRECT MAIL','DM', 'DOOR TO DOOR') THEN 'DM'
            ELSE 'Other' END AS channel
      ,CASE WHEN p.ESID_PREMISE LIKE ('%RES%') THEN 'RES' ELSE 'BUS' END AS meter_type
      ,CASE WHEN p.PRODUCT_GROUP LIKE ('%MTM%') THEN 'MTM' ELSE 'TERM' END AS product_group
      ,SUM(CASE WHEN p.CATEGORY IN ('MASS_PORTFOLIO_ACTUAL') THEN p.GAIN ELSE 0 END) AS gains
      ,SUM(CASE WHEN p.CATEGORY IN ('PORTFOLIO_PLAN') THEN p.GAIN ELSE 0 END) AS [plan]
      ,SUM(CASE WHEN p.CATEGORY IN ('MASS_PORTFOLIO_ACTUAL') THEN p.LOSS ELSE 0 END) AS losses
FROM Skywalker.dbo.Mass_Plan_Proj_Actual p
WHERE p.CHANNEL IS NOT NULL
AND p.YEARMONTH <= FORMAT(GETDATE(),'yyyyMM')
AND p.YEARMONTH >= '202401'
GROUP BY LEFT(p.YEARMONTH,4)
      ,RIGHT(p.YEARMONTH,2), YEARMONTH
      ,CASE WHEN p.CHANNEL IN ('REACTIVE','WEB PHONE REACTIVE','CALL CENTER') THEN 'Call Center'
            WHEN p.CHANNEL IN ('WEB SEARCH','WEB_SEARCH','EMAIL/RAF') THEN 'Web Search'
            WHEN p.CHANNEL IN ('ONLINE PARTNER') THEN 'SOE'
            WHEN p.CHANNEL IN ('RAQ','REQUEST A QUOTE') THEN 'RAQ'
            WHEN p.CHANNEL IN ('BAAT','OBTM','OUTBOUND') THEN 'BAAT'
            WHEN p.CHANNEL IN ('DIRECT MAIL','DM', 'DOOR TO DOOR') THEN 'DM'
            ELSE 'Other' END
      ,CASE WHEN p.ESID_PREMISE LIKE ('%RES%') THEN 'RES' ELSE 'BUS' END
      ,CASE WHEN p.PRODUCT_GROUP LIKE ('%MTM%') THEN 'MTM' ELSE 'TERM' END
ORDER BY YEARMONTH DESC
"""

def get_db_connection():
    """
    Create database connection using environment variables for credentials.
    Required environment variables:
    - DB_SERVER: Database server address
    - DB_DATABASE: Database name
    - DB_USERNAME: Database username
    - DB_PASSWORD: Database password
    """
    server = os.environ.get('DB_SERVER')
    database = os.environ.get('DB_DATABASE')
    username = os.environ.get('DB_USERNAME')
    password = os.environ.get('DB_PASSWORD')

    if not all([server, database, username, password]):
        missing = [var for var in ['DB_SERVER', 'DB_DATABASE', 'DB_USERNAME', 'DB_PASSWORD']
                   if not os.environ.get(var)]
        raise EnvironmentError(f"Missing required environment variables: {', '.join(missing)}")

    # Try available ODBC drivers in order of preference
    available_drivers = pyodbc.drivers()
    driver_name = None
    for preferred in ['ODBC Driver 18 for SQL Server', 'ODBC Driver 17 for SQL Server', 'SQL Server']:
        if preferred in available_drivers:
            driver_name = preferred
            break
    if not driver_name:
        raise EnvironmentError(f"No SQL Server ODBC driver found. Available: {', '.join(available_drivers)}")

    conn_str = (
        f'DRIVER={{{driver_name}}};'
        f'SERVER={server};'
        f'DATABASE={database};'
        f'UID={username};'
        f'PWD={password};'
    )
    if '18' in driver_name:
        conn_str += 'TrustServerCertificate=yes;'

    return pyodbc.connect(conn_str)

def fetch_data_to_csv(output_file='data/dashboard_data.csv'):
    """
    Execute SQL query and save results to CSV file.

    Args:
        output_file: Path where CSV file will be saved

    Returns:
        tuple: (success: bool, message: str, row_count: int)
    """
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Connecting to database...")
        conn = get_db_connection()

        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Executing query...")
        df = pd.read_sql(SQL_QUERY, conn)

        conn.close()

        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_file), exist_ok=True)

        # Save to CSV
        df.to_csv(output_file, index=False)

        row_count = len(df)
        message = f"Successfully fetched {row_count} rows and saved to {output_file}"
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}")

        # Print summary statistics
        if row_count > 0:
            print(f"\nData Summary:")
            print(f"  Date Range: {df['year'].min()}-{df['month'].min()} to {df['year'].max()}-{df['month'].max()}")
            print(f"  Total Gains: {df['gains'].sum():,.0f}")
            print(f"  Total Plan: {df['plan'].sum():,.0f}")
            print(f"  Total Losses: {df['losses'].sum():,.0f}")

        return True, message, row_count

    except Exception as e:
        error_msg = f"Error fetching data: {str(e)}"
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {error_msg}", file=sys.stderr)
        return False, error_msg, 0

if __name__ == '__main__':
    success, message, row_count = fetch_data_to_csv()

    if not success:
        sys.exit(1)

    print(f"\n✓ Data refresh completed successfully at {datetime.now().strftime('%Y-%m-%d %H:%M:%S CT')}")
