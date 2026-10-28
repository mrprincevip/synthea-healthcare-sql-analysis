"""
Load Synthea CSV files into a SQLite database.

Usage:
    python load_data.py path/to/synthea/csv/folder

Creates synthea.db in this folder with one table per CSV file.
pandas detects number columns, so costs and incomes load as numbers, not text.
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

# Only the tables this project uses (observations.csv alone can be millions of rows).
TABLES = ["patients", "encounters", "conditions", "medications",
          "payers", "organizations", "providers"]


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("Usage: python load_data.py path/to/synthea/csv/folder")

    csv_dir = Path(sys.argv[1])
    db_path = Path(__file__).parent / "synthea.db"
    conn = sqlite3.connect(db_path)

    for table in TABLES:
        csv_file = csv_dir / f"{table}.csv"
        if not csv_file.exists():
            print(f"  skipped {table}: {csv_file.name} not found")
            continue
        df = pd.read_csv(csv_file, low_memory=False)
        df.columns = [c.upper() for c in df.columns]
        df.to_sql(table, conn, if_exists="replace", index=False)
        print(f"  loaded {table:<14} {len(df):>9,} rows")

    conn.close()
    print(f"\nDone. Open {db_path.name} in DB Browser for SQLite and run the files in queries/.")


if __name__ == "__main__":
    main()
