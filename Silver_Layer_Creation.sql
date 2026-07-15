-- =============================================
-- SILVER LAYER - TABLE DEFINITIONS
-- =============================================

CREATE TABLE IF NOT EXISTS silver_olist.category_translation
(
    product_category_name         text,
    product_category_name_english text
);

CREATE TABLE IF NOT EXISTS silver_olist.customers
(
    customer_id              text,
    customer_unique_id       text,
    customer_zip_code_prefix bigint,
    customer_city            text,
    customer_state           text
);

CREATE TABLE IF NOT EXISTS silver_olist.geolocation
(
    geolocation_zip_code_prefix bigint,
    geolocation_lat             double precision,
    geolocation_lng             double precision,
    geolocation_city            text,
    geolocation_state           text
);

CREATE TABLE IF NOT EXISTS silver_olist.order_items
(
    order_id             text,
    order_item_id        bigint,
    product_id           text,
    seller_id            text,
    shipping_limit_date  text,
    price                double precision,
    freight_value        double precision
);

CREATE TABLE IF NOT EXISTS silver_olist.order_payments
(
    order_id              text,
    payment_sequential    bigint,
    payment_type          text,
    payment_installments  bigint,
    payment_value         double precision
);

CREATE TABLE IF NOT EXISTS silver_olist.order_reviews
(
    review_id                text,
    order_id                 text,
    review_score             bigint,
    review_comment_title     text,
    review_comment_message   text,
    review_creation_date     text,
    review_answer_timestamp  text
);

CREATE TABLE IF NOT EXISTS silver_olist.orders
(
    order_id                       text,
    customer_id                    text,
    order_status                   text,
    order_purchase_timestamp       text,
    order_approved_at              text,
    order_delivered_carrier_date   text,
    order_delivered_customer_date  text,
    order_estimated_delivery_date  text
);

CREATE TABLE IF NOT EXISTS silver_olist.products
(
    product_id                   text,
    product_category_name        text,
    product_name_lenght          double precision,
    product_description_lenght   double precision,
    product_photos_qty           double precision,
    product_weight_g             double precision,
    product_length_cm            double precision,
    product_height_cm            double precision,
    product_width_cm             double precision
);

CREATE TABLE IF NOT EXISTS silver_olist.sellers
(
    seller_id              text,
    seller_zip_code_prefix bigint,
    seller_city            text,
    seller_state           text
);