"""
Load Synthea CSV files into a MySQL database (for MySQL Workbench).

Usage:
    pip install pandas sqlalchemy pymysql
    python load_data_mysql.py path/to/synthea/csv/folder --user root

You will be asked for your MySQL password. The script creates a database
called `synthea` (change it with --database) with one table per CSV file,
converts date columns to real DATE/DATETIME types, and adds indexes on the
ID columns so joins run fast.
"""
import argparse
import getpass
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.types import String

TABLES = ["patients", "encounters", "conditions", "medications",
          "payers", "organizations", "providers"]

# Columns that hold dates only vs full timestamps (per Synthea's data dictionary)
DATE_COLS = {"patients": ["BIRTHDATE", "DEATHDATE"],
             "conditions": ["START", "STOP"]}
DATETIME_COLS = {"encounters": ["START", "STOP"],
                 "medications": ["START", "STOP"]}

# ID columns get a fixed-length type so MySQL can index them
ID_COLS = {"ID", "PATIENT", "ENCOUNTER", "PAYER", "ORGANIZATION", "PROVIDER"}
INDEXES = {"patients": ["ID"],
           "encounters": ["ID", "PATIENT", "PAYER", "ORGANIZATION"],
           "conditions": ["PATIENT", "ENCOUNTER"],
           "medications": ["PATIENT", "ENCOUNTER"],
           "payers": ["ID"], "organizations": ["ID"], "providers": ["ID"]}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("csv_dir")
    ap.add_argument("--user", default="root")
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", default="3306")
    ap.add_argument("--database", default="synthea")
    ap.add_argument("--password", help="omit to be prompted")
    args = ap.parse_args()
    pw = args.password if args.password is not None else getpass.getpass("MySQL password: ")

    server = create_engine(f"mysql+pymysql://{args.user}:{pw}@{args.host}:{args.port}/")
    with server.begin() as conn:
        conn.execute(text(f"CREATE DATABASE IF NOT EXISTS `{args.database}`"))
    engine = create_engine(f"mysql+pymysql://{args.user}:{pw}@{args.host}:{args.port}/{args.database}")

    csv_dir = Path(args.csv_dir)
    for table in TABLES:
        csv_file = csv_dir / f"{table}.csv"
        if not csv_file.exists():
            print(f"  skipped {table}: {csv_file.name} not found")
            continue
        df = pd.read_csv(csv_file, low_memory=False)
        df.columns = [c.upper() for c in df.columns]

        for col in DATE_COLS.get(table, []):
            if col in df:
                df[col] = pd.to_datetime(df[col], errors="coerce").dt.date
        for col in DATETIME_COLS.get(table, []):
            if col in df:
                df[col] = pd.to_datetime(df[col], errors="coerce", utc=True).dt.tz_localize(None)

        dtypes = {c: String(64) for c in df.columns if c in ID_COLS}
        df.to_sql(table, engine, if_exists="replace", index=False, chunksize=5000, dtype=dtypes)

        with engine.begin() as conn:
            for col in INDEXES.get(table, []):
                if col in df.columns:
                    conn.execute(text(f"CREATE INDEX idx_{table}_{col.lower()} ON `{table}` (`{col}`)"))
        print(f"  loaded {table:<14} {len(df):>9,} rows")

    print(f"\nDone. In MySQL Workbench, run:  USE {args.database};  then open the files in mysql/queries/.")


if __name__ == "__main__":
    main()
