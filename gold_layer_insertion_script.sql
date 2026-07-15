-- Covers full Olist data range 2016 to 2019
INSERT INTO gold_olist.dim_date
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT          AS date_sk,
    d::DATE                              AS full_date,
    EXTRACT(DAY   FROM d)::INT           AS day,
    EXTRACT(MONTH FROM d)::INT           AS month,
    TO_CHAR(d, 'Month')                  AS month_name,
    EXTRACT(QUARTER FROM d)::INT         AS quarter,
    EXTRACT(YEAR  FROM d)::INT           AS year,
    EXTRACT(WEEK  FROM d)::INT           AS week_of_year,
    EXTRACT(DOW   FROM d)::INT           AS day_of_week,
    TO_CHAR(d, 'Day')                    AS day_name,
    CASE WHEN EXTRACT(DOW FROM d) 
         IN (0,6) THEN TRUE ELSE FALSE 
    END                                  AS is_weekend
FROM generate_series(
    '2016-01-01'::DATE,
    '2019-12-31'::DATE,
    '1 day'
) AS d;

-- Verify
SELECT COUNT(*) FROM gold_olist.dim_date;  -- should be 1461

INSERT INTO gold_olist.dim_customer
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM silver_olist.customers;

-- Verify
SELECT COUNT(*) FROM gold_olist.dim_customer;  -- 99441

-- Join with category_translation to get English name
INSERT INTO gold_olist.dim_product
(
    product_id,
    product_category_name,
    product_category_name_english,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_photos_qty
)
SELECT
    p.product_id,
    p.product_category_name,
    COALESCE(ct.product_category_name_english, 'uncategorized'),
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_photos_qty
FROM silver_olist.products p
LEFT JOIN silver_olist.category_translation ct
    ON p.product_category_name = ct.product_category_name;

-- Verify
SELECT COUNT(*) FROM gold_olist.dim_product;  -- 32951



INSERT INTO gold_olist.dim_seller
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM silver_olist.sellers;

-- Verify
SELECT COUNT(*) FROM gold_olist.dim_seller;  -- 3095


-- Pull distinct payment types from silver
INSERT INTO gold_olist.dim_payment_type (payment_type)
SELECT DISTINCT payment_type
FROM silver_olist.order_payments
ORDER BY payment_type;

-- Verify (should be 4 rows: credit_card, boleto, voucher, debit_card)
SELECT * FROM gold_olist.dim_payment_type;



-- Grain: one row = one order line item
INSERT INTO gold_olist.fact_order_items
(
    order_id,
    order_item_id,
    date_sk,
    customer_sk,
    product_sk,
    seller_sk,
    order_status,
    price,
    freight_value,
    total_item_value,
    review_score,
    actual_delivery_days,
    delivery_status
)
SELECT
    oi.order_id,
    oi.order_item_id,

    -- date_sk: from order purchase timestamp
    TO_CHAR(
        TO_TIMESTAMP(o.order_purchase_timestamp,
        'YYYY-MM-DD HH24:MI:SS'), 'YYYYMMDD'
    )::INT                                          AS date_sk,

    -- customer_sk: lookup from dim_customer
    dc.customer_sk,

    -- product_sk: lookup from dim_product
    dp.product_sk,

    -- seller_sk: lookup from dim_seller
    ds.seller_sk,

    o.order_status,
    oi.price,
    oi.freight_value,

    -- derived measure
    ROUND((oi.price + oi.freight_value)::NUMERIC, 2) AS total_item_value,

    -- review score from order_reviews
    orv.review_score,

    -- actual delivery days
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN DATE_PART('day',
             TO_TIMESTAMP(o.order_delivered_customer_date, 'YYYY-MM-DD HH24:MI:SS') -
             TO_TIMESTAMP(o.order_purchase_timestamp,      'YYYY-MM-DD HH24:MI:SS')
             )::INT
        ELSE NULL
    END                                              AS actual_delivery_days,

    -- delivery status flag
    CASE
        WHEN o.order_status IN ('cancelled','unavailable')    THEN 'CANCELLED'
        WHEN o.order_delivered_customer_date IS NULL          THEN 'PENDING'
        WHEN o.order_delivered_customer_date
           > o.order_estimated_delivery_date                  THEN 'LATE'
        ELSE 'ON_TIME'
    END                                              AS delivery_status

FROM silver_olist.order_items oi

-- join orders to get date, customer, status, delivery info
JOIN silver_olist.orders o
    ON oi.order_id = o.order_id

-- lookup customer_sk
JOIN silver_olist.customers c
    ON o.customer_id = c.customer_id
JOIN gold_olist.dim_customer dc
    ON c.customer_id = dc.customer_id

-- lookup product_sk
JOIN gold_olist.dim_product dp
    ON oi.product_id = dp.product_id

-- lookup seller_sk
JOIN gold_olist.dim_seller ds
    ON oi.seller_id = ds.seller_id

-- get review score (LEFT JOIN — not all orders have reviews)
LEFT JOIN silver_olist.order_reviews orv
    ON oi.order_id = orv.order_id;

-- Verify
SELECT COUNT(*) FROM gold_olist.fact_order_items;  -- ~112650




-- Grain: one row = one payment record
INSERT INTO gold_olist.fact_order_payments
(
    order_id,
    date_sk,
    customer_sk,
    payment_type_sk,
    payment_sequential,
    payment_installments,
    payment_value
)
SELECT
    op.order_id,

    -- date_sk from order purchase timestamp
    TO_CHAR(
        TO_TIMESTAMP(o.order_purchase_timestamp,
        'YYYY-MM-DD HH24:MI:SS'), 'YYYYMMDD'
    )::INT                    AS date_sk,

    -- customer_sk lookup
    dc.customer_sk,

    -- payment_type_sk lookup
    dpt.payment_type_sk,

    op.payment_sequential,
    op.payment_installments,
    op.payment_value

FROM silver_olist.order_payments op

-- join orders for date and customer
JOIN silver_olist.orders o
    ON op.order_id = o.order_id

-- lookup customer_sk
JOIN silver_olist.customers c
    ON o.customer_id = c.customer_id
JOIN gold_olist.dim_customer dc
    ON c.customer_id = dc.customer_id

-- lookup payment_type_sk
JOIN gold_olist.dim_payment_type dpt
    ON op.payment_type = dpt.payment_type;

-- Verify
SELECT COUNT(*) FROM gold_olist.fact_order_payments;  -- ~103886


