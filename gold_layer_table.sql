-- =============================================
-- GOLD LAYER - DIMENSION TABLE DEFINITIONS
-- =============================================

-- 1. dim_date (generated, not from source)
CREATE TABLE IF NOT EXISTS gold_olist.dim_date
(
    date_sk         INT PRIMARY KEY,  -- format YYYYMMDD
    full_date       DATE,
    day             INT,
    month           INT,
    month_name      TEXT,
    quarter         INT,
    year            INT,
    week_of_year    INT,
    day_of_week     INT,
    day_name        TEXT,
    is_weekend      BOOLEAN
);

-- 2. dim_customer
CREATE TABLE IF NOT EXISTS gold_olist.dim_customer
(
    customer_sk              SERIAL PRIMARY KEY,
    customer_id              TEXT,
    customer_unique_id       TEXT,
    customer_zip_code_prefix BIGINT,
    customer_city            TEXT,
    customer_state           TEXT
);

-- 3. dim_product
CREATE TABLE IF NOT EXISTS gold_olist.dim_product
(
    product_sk                     SERIAL PRIMARY KEY,
    product_id                     TEXT,
    product_category_name          TEXT,
    product_category_name_english  TEXT,
    product_weight_g               DOUBLE PRECISION,
    product_length_cm              DOUBLE PRECISION,
    product_height_cm              DOUBLE PRECISION,
    product_width_cm               DOUBLE PRECISION,
    product_photos_qty             DOUBLE PRECISION
);

-- 4. dim_seller
CREATE TABLE IF NOT EXISTS gold_olist.dim_seller
(
    seller_sk              SERIAL PRIMARY KEY,
    seller_id              TEXT,
    seller_zip_code_prefix BIGINT,
    seller_city            TEXT,
    seller_state           TEXT
);

-- 5. dim_payment_type
CREATE TABLE IF NOT EXISTS gold_olist.dim_payment_type
(
    payment_type_sk  SERIAL PRIMARY KEY,
    payment_type     TEXT
);

-- =============================================
-- GOLD LAYER - FACT TABLE DEFINITIONS
-- =============================================

-- 6. fact_order_items  (grain: one row = one item in one order)
CREATE TABLE IF NOT EXISTS gold_olist.fact_order_items
(
    order_item_sk          SERIAL PRIMARY KEY,
    order_id               TEXT,
    order_item_id          BIGINT,
    date_sk                INT REFERENCES gold_olist.dim_date(date_sk),
    customer_sk            INT REFERENCES gold_olist.dim_customer(customer_sk),
    product_sk             INT REFERENCES gold_olist.dim_product(product_sk),
    seller_sk              INT REFERENCES gold_olist.dim_seller(seller_sk),
    order_status           TEXT,
    price                  DOUBLE PRECISION,
    freight_value          DOUBLE PRECISION,
    total_item_value       DOUBLE PRECISION,
    review_score           BIGINT,
    actual_delivery_days   INT,
    delivery_status        TEXT
);

-- 7. fact_order_payments  (grain: one row = one payment record)
CREATE TABLE IF NOT EXISTS gold_olist.fact_order_payments
(
    payment_sk            SERIAL PRIMARY KEY,
    order_id              TEXT,
    date_sk               INT REFERENCES gold_olist.dim_date(date_sk),
    customer_sk           INT REFERENCES gold_olist.dim_customer(customer_sk),
    payment_type_sk       INT REFERENCES gold_olist.dim_payment_type(payment_type_sk),
    payment_sequential    BIGINT,
    payment_installments  BIGINT,
    payment_value         DOUBLE PRECISION
);