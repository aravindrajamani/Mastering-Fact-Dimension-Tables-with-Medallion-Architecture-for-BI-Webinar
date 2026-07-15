import time
import pandas as pd
from sqlalchemy import create_engine, text

# ==========================================================
# MYSQL CONNECTION
# ==========================================================

MYSQL_USER = "root"
MYSQL_PASSWORD = "krishna"
MYSQL_HOST = "localhost"
MYSQL_PORT = 3306
MYSQL_DATABASE = "olist_prd"

mysql_engine = create_engine(
    f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}"
)

# ==========================================================
# POSTGRESQL CONNECTION
# ==========================================================

POSTGRES_USER = "postgres"
POSTGRES_PASSWORD = "krishna"
POSTGRES_HOST = "localhost"
POSTGRES_PORT = 5432
POSTGRES_DATABASE = "olist_dwh"

postgres_engine = create_engine(
    f"postgresql+psycopg2://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DATABASE}"
)

# ==========================================================
# SOURCE TABLE --> TARGET TABLE
# ==========================================================

tables = {
    "customers": "customers",
    "orders": "orders",
    "order_items": "order_items",
    "order_payments": "order_payments",
    "order_reviews": "order_reviews",
    "products": "products",
    "sellers": "sellers",
    "geolocation": "geolocation",
    "category_translation": "category_translation"
}

# ==========================================================
# CREATE BRONZE SCHEMA
# ==========================================================

with postgres_engine.begin() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS bronze_olist;"))

# ==========================================================
# ETL START
# ==========================================================

start_time = time.time()

print("\n")
print("=" * 70)
print("MYSQL --> POSTGRESQL BRONZE LOAD")
print("=" * 70)

for source_table, target_table in tables.items():

    print(f"\nLoading Table : {source_table}")

    try:

        # -----------------------------------------
        # Read data from MySQL
        # -----------------------------------------

        df = pd.read_sql(
            f"SELECT * FROM {source_table}",
            mysql_engine
        )

        print(f"MySQL Rows      : {len(df):,}")

        # -----------------------------------------
        # Check if table exists
        # -----------------------------------------

        check_sql = f"""
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema='bronze_olist'
            AND table_name='{target_table}'
        );
        """

        table_exists = pd.read_sql(check_sql, postgres_engine).iloc[0, 0]

        # -----------------------------------------
        # First Run
        # -----------------------------------------

        if not table_exists:

            print("Creating table...")

            df.head(0).to_sql(
                target_table,
                postgres_engine,
                schema="bronze_olist",
                if_exists="replace",
                index=False
            )

        else:

            with postgres_engine.begin() as conn:
                conn.execute(
                    text(f'TRUNCATE TABLE bronze_olist."{target_table}" RESTART IDENTITY;')
                )

        # -----------------------------------------
        # Load data
        # -----------------------------------------

        df.to_sql(
            target_table,
            postgres_engine,
            schema="bronze_olist",
            if_exists="append",
            index=False,
            chunksize=10000,
            method="multi"
        )

        count = pd.read_sql(
            f'SELECT COUNT(*) cnt FROM bronze_olist."{target_table}"',
            postgres_engine
        ).iloc[0, 0]

        print(f"Postgres Rows   : {count:,}")
        print("Status          : SUCCESS")

    except Exception as ex:

        print("Status          : FAILED")
        print(ex)

print("\n")
print("=" * 70)
print("ETL COMPLETED SUCCESSFULLY")
print("=" * 70)
print(f"Execution Time : {round(time.time()-start_time,2)} Seconds")