# 🏗️ Mastering Fact & Dimension Tables with Medallion Architecture for BI Reporting

> A practical, end-to-end implementation of a Modern Data Warehouse using the **Olist Brazilian E-Commerce Dataset** — built for the July 2025 Internal Data Engineering Webinar.

---

## 📌 Overview

In most organizations, data lives scattered across multiple systems with no single place to answer business questions reliably. This project demonstrates how to solve that problem using the **Medallion Architecture (Bronze → Silver → Gold)**.

We ingest raw data from **MySQL** into **PostgreSQL**, apply minimal cleaning in the **Silver layer**, build a complete **Star Schema** with Fact and Dimension tables in the **Gold layer**, and connect everything to **Apache Superset** for BI reporting.

---

## 🗂️ Dataset

**Olist Brazilian E-Commerce Public Dataset** — available on [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

| Table | Description | Rows |
|---|---|---|
| `customers` | Customer details and location | 99,441 |
| `orders` | Order lifecycle and timestamps | 99,441 |
| `order_items` | Line items per order | 112,650 |
| `order_payments` | Payment details per order | 103,886 |
| `order_reviews` | Customer review scores | 99,224 |
| `products` | Product catalog | 32,951 |
| `sellers` | Seller details and location | 3,095 |
| `geolocation` | ZIP to city/state mapping | 1,000,163 |
| `category_translation` | Portuguese to English category names | 71 |

---

## 🏛️ Architecture

<img width="661" height="491" alt="Olist_datawarehouse_architecture drawio" src="https://github.com/user-attachments/assets/f5e00ba5-cabb-4475-9144-855f0922e9fc" />


```
┌──────────────────────────────────────────────────────────┐
│                    SOURCE SYSTEMS                         │
│              MySQL (olist_prd) — 9 tables                 │
└───────────────────────┬──────────────────────────────────┘
                        │
               🐍 Python Ingestion Script
                        │
┌───────────────────────▼──────────────────────────────────┐
│              BRONZE LAYER  (bronze_olist)                 │
│    Raw data loaded as-is — metadata columns added         │
│              ingested_at | source_system                  │
└───────────────────────┬──────────────────────────────────┘
                        │
                  🔧 SQL — TRIM only
                        │
┌───────────────────────▼──────────────────────────────────┐
│              SILVER LAYER  (silver_olist)                 │
│    TRIM on all text columns — all rows preserved          │
└───────────────────────┬──────────────────────────────────┘
                        │
                  ⭐ SQL — Star Schema Build
                        │
┌───────────────────────▼──────────────────────────────────┐
│               GOLD LAYER  (gold_olist)                    │
│                                                           │
│   FACT TABLES            DIMENSION TABLES                 │
│   ─────────────          ────────────────                 │
│   fact_order_items  ──►  dim_date                         │
│   fact_order_payments──► dim_customer                     │
│                          dim_product                      │
│                          dim_seller                       │
│                          dim_payment_type                 │
└───────────────────────┬──────────────────────────────────┘
                        │
              📊 Apache Superset (Docker)
                        │
┌───────────────────────▼──────────────────────────────────┐
│                   BI DASHBOARDS                           │
│   Dashboard 1 — Sales Performance (Gold Layer)            │
│   Dashboard 2 — Sales Report (MySQL Raw Source)           │
└──────────────────────────────────────────────────────────┘
```

> All three layers live inside a single **PostgreSQL** instance (`olist_DWH`) as separate schemas.

---

## 📁 Repository Structure

```
├── 01_mysql_setup/
│   └── create_tables.sql           # DDL for all 9 MySQL source tables
│
├── 02_bronze_layer/
│   └── ingest_mysql_to_bronze.py   # Python script — MySQL → PostgreSQL bronze
│
├── 03_silver_layer/
│   └── bronze_to_silver.sql        # TRIM + load all tables to silver schema
│
├── 04_gold_layer/
│   ├── dim_date.sql                # dim_date — generated via generate_series
│   ├── dim_customer.sql            # dim_customer DDL + INSERT
│   ├── dim_product.sql             # dim_product DDL + INSERT (with English category)
│   ├── dim_seller.sql              # dim_seller DDL + INSERT
│   ├── dim_payment_type.sql        # dim_payment_type DDL + INSERT
│   ├── fact_order_items.sql        # fact_order_items DDL + INSERT
│   └── fact_order_payments.sql     # fact_order_payments DDL + INSERT
│
├── 05_validation/
│   └── row_count_checks.sql        # Verify counts across all layers
│
└── README.md
```

---

## ⚙️ Tech Stack

| Tool | Purpose |
|---|---|
| MySQL 8 | Source database — raw Olist data |
| PostgreSQL 18 | Data Warehouse — Bronze, Silver, Gold schemas |
| Python 3 | Data ingestion (pandas, sqlalchemy, mysql-connector) |
| Apache Superset | BI dashboards and reporting |
| Docker | Runs Apache Superset |
| pgAdmin 4 | PostgreSQL query tool |
| MySQL Workbench | MySQL query tool and CSV import |

---

## 🚀 Getting Started

### Prerequisites

- MySQL 8+ installed and running
- PostgreSQL 18 installed and running
- Python 3.8+ with pip
- Docker Desktop installed

### Step 1 — Clone the Repository

```bash
git clone https://github.com/aravindrajamani/Mastering-Fact-Dimension-Tables-with-Medallion-Architecture-for-BI-Webinar.git
cd Mastering-Fact-Dimension-Tables-with-Medallion-Architecture-for-BI-Webinar
```

### Step 2 — Download Dataset

Download all 9 CSV files from [Kaggle Olist Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and place them in a local folder.

### Step 3 — Setup MySQL Source Database

```sql
CREATE DATABASE olist_prd;
USE olist_prd;
```

Run `01_mysql_setup/create_tables.sql` in MySQL Workbench, then import all 9 CSVs using the **Table Data Import Wizard**.

### Step 4 — Setup PostgreSQL Schemas

```sql
CREATE DATABASE olist_DWH;

CREATE SCHEMA bronze_olist;
CREATE SCHEMA silver_olist;
CREATE SCHEMA gold_olist;
```

### Step 5 — Install Python Dependencies

```bash
pip install pandas sqlalchemy mysql-connector-python psycopg2-binary
```

### Step 6 — Run Bronze Ingestion

Update connection details in the script, then run:

```bash
python 02_bronze_layer/ingest_mysql_to_bronze.py
```

Expected output:
```
Ingesting: customers     → 99,441 rows loaded into bronze_olist.customers
Ingesting: orders        → 99,441 rows loaded into bronze_olist.orders
Ingesting: order_items   → 112,650 rows loaded into bronze_olist.order_items
...
Bronze ingestion complete.
```

### Step 7 — Run Silver Layer

```bash
psql -U postgres -d olist_DWH -f 03_silver_layer/bronze_to_silver.sql
```

### Step 8 — Build Gold Layer

Run in this exact order:

```bash
psql -U postgres -d olist_DWH -f 04_gold_layer/dim_date.sql
psql -U postgres -d olist_DWH -f 04_gold_layer/dim_customer.sql
psql -U postgres -d olist_DWH -f 04_gold_layer/dim_product.sql
psql -U postgres -d olist_DWH -f 04_gold_layer/dim_seller.sql
psql -U postgres -d olist_DWH -f 04_gold_layer/dim_payment_type.sql
psql -U postgres -d olist_DWH -f 04_gold_layer/fact_order_items.sql
psql -U postgres -d olist_DWH -f 04_gold_layer/fact_order_payments.sql
```

> ⚠️ Dimension tables must be built **before** fact tables.

### Step 9 — Validate

```bash
psql -U postgres -d olist_DWH -f 05_validation/row_count_checks.sql
```

Expected results:

| Table | Expected Rows |
|---|---|
| dim_date | 1,461 |
| dim_customer | 99,441 |
| dim_product | 32,951 |
| dim_seller | 3,095 |
| dim_payment_type | 4 |
| fact_order_items | ~112,650 |
| fact_order_payments | ~103,886 |

---

## ⭐ Gold Layer — Star Schema

### Fact Tables

#### `fact_order_items` — Primary Fact Table
> **Grain:** One row = one item within one order

| Column | Type | Description |
|---|---|---|
| `order_item_sk` | SERIAL PK | Surrogate key |
| `date_sk` | INT | FK → dim_date |
| `customer_sk` | INT | FK → dim_customer |
| `product_sk` | INT | FK → dim_product |
| `seller_sk` | INT | FK → dim_seller |
| `price` | DOUBLE | Item price |
| `freight_value` | DOUBLE | Shipping cost |
| `total_item_value` | DOUBLE | price + freight |
| `review_score` | BIGINT | Customer rating (1–5) |
| `actual_delivery_days` | INT | Days from purchase to delivery |
| `delivery_status` | TEXT | ON_TIME / LATE / PENDING / CANCELLED |

#### `fact_order_payments` — Secondary Fact Table
> **Grain:** One row = one payment record per order

| Column | Type | Description |
|---|---|---|
| `payment_sk` | SERIAL PK | Surrogate key |
| `date_sk` | INT | FK → dim_date |
| `customer_sk` | INT | FK → dim_customer |
| `payment_type_sk` | INT | FK → dim_payment_type |
| `payment_installments` | BIGINT | Number of installments |
| `payment_value` | DOUBLE | Payment amount |

### Dimension Tables

| Dimension | Key Columns | Used For |
|---|---|---|
| `dim_date` | year, month, quarter, is_weekend | Time-based analysis |
| `dim_customer` | city, state, zip | Customer location analysis |
| `dim_product` | category_english, weight | Product performance |
| `dim_seller` | city, state | Seller location analysis |
| `dim_payment_type` | payment_type | Payment method analysis |

---

## 📊 Superset Dashboards

### Dashboard 1 — Sales Performance (Gold Layer)

| Chart | Type | Measure |
|---|---|---|
| Total Revenue | Big Number | SUM(total_item_value) |
| Monthly Revenue Trend | Line Chart | SUM(price) by month |
| Revenue by Category | Bar Chart | SUM(price) by category_english |
| Top 10 Categories | Horizontal Bar | COUNT(*) by category |
| Orders by State | Country Map | COUNT(order_id) by state |
| Avg Delivery Days | Heatmap Table | AVG(actual_delivery_days) by state |

### Dashboard 2 — Sales Report (MySQL Raw Source)

Same charts built directly on MySQL raw tables — used for side-by-side comparison with the Gold Layer to demonstrate the value of the star schema.

---

## 💡 Key Learnings

- **Bronze** = Raw data exactly as-is. No transformations. Just add metadata.
- **Silver** = Standardize text with TRIM. Keep all rows. Never delete data.
- **Gold** = Star Schema. Fact tables store measures. Dimension tables store context.
- **Surrogate keys** decouple the warehouse from source system IDs.
- **dim_date** is always generated — never sourced from the data.
- **Grain declaration** is the most critical modeling decision — define it before writing any SQL.

---

## 👤 Author

**Aravind** — Senior Data Engineer  
📧 For queries or collaboration, reach out via GitHub.

