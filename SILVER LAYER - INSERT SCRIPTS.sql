-- =============================================
-- SILVER LAYER - INSERT SCRIPTS
-- =============================================

-- 1. category_translation
INSERT INTO silver_olist.category_translation
SELECT
    TRIM(product_category_name),
    TRIM(product_category_name_english)
FROM bronze_olist.category_translation;

-- 2. customers
INSERT INTO silver_olist.customers
SELECT
    TRIM(customer_id),
    TRIM(customer_unique_id),
    customer_zip_code_prefix,
    TRIM(customer_city),
    TRIM(customer_state)
FROM bronze_olist.customers;

-- 3. geolocation
INSERT INTO silver_olist.geolocation
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    TRIM(geolocation_city),
    TRIM(geolocation_state)
FROM bronze_olist.geolocation;

-- 4. order_items
INSERT INTO silver_olist.order_items
SELECT
    TRIM(order_id),
    order_item_id,
    TRIM(product_id),
    TRIM(seller_id),
    TRIM(shipping_limit_date),
    price,
    freight_value
FROM bronze_olist.order_items;

-- 5. order_payments
INSERT INTO silver_olist.order_payments
SELECT
    TRIM(order_id),
    payment_sequential,
    TRIM(payment_type),
    payment_installments,
    payment_value
FROM bronze_olist.order_payments;

-- 6. order_reviews
INSERT INTO silver_olist.order_reviews
SELECT
    TRIM(review_id),
    TRIM(order_id),
    review_score,
    TRIM(review_comment_title),
    TRIM(review_comment_message),
    TRIM(review_creation_date),
    TRIM(review_answer_timestamp)
FROM bronze_olist.order_reviews;

-- 7. orders
INSERT INTO silver_olist.orders
SELECT
    TRIM(order_id),
    TRIM(customer_id),
    TRIM(order_status),
    TRIM(order_purchase_timestamp),
    TRIM(order_approved_at),
    TRIM(order_delivered_carrier_date),
    TRIM(order_delivered_customer_date),
    TRIM(order_estimated_delivery_date)
FROM bronze_olist.orders;

-- 8. products
INSERT INTO silver_olist.products
SELECT
    TRIM(product_id),
    TRIM(product_category_name),
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM bronze_olist.products;

-- 9. sellers
INSERT INTO silver_olist.sellers
SELECT
    TRIM(seller_id),
    seller_zip_code_prefix,
    TRIM(seller_city),
    TRIM(seller_state)
FROM bronze_olist.sellers;