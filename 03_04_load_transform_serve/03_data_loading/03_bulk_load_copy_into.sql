-- Module 3: Data Loading
-- Bulk-load the bronze tables with COPY INTO.
-- Run 01_setup_environment.sql and 02_stage_files.sql first.

USE DATABASE LOAD_TRANSFORM_SERVE;
USE SCHEMA BRONZE;

-- These are direct CSV loads. Explicit file lists make the load repeatable and
-- avoid loading the intentionally malformed CSV from the same stage.
COPY INTO BRONZE_CUSTOMERS (
  CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE,
  CITY, COUNTRY, SIGNUP_DATE, MARKETING_OPT_IN
)
FROM @BRONZE_CSV_STAGE
FILES = ('customers.csv')
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO BRONZE_ORDERS (
  ORDER_ID, CUSTOMER_ID, ORDER_DATE, STATUS, SALES_CHANNEL,
  CURRENCY, ORDER_TOTAL, DISCOUNT_AMOUNT, SHIPPING_CITY, SHIPPING_COUNTRY
)
FROM @BRONZE_CSV_STAGE
FILES = ('orders.csv')
ON_ERROR = 'ABORT_STATEMENT';

-- This is a small load-time transformation: Parquet fields are mapped and
-- cast into the bronze schema, the nested attributes object stays VARIANT,
-- and the staged filename is retained for lineage. No business rules are
-- applied; richer transformations belong to the next module.
COPY INTO BRONZE_PRODUCT_CATALOG (
  PRODUCT_ID, SKU, PRODUCT_NAME, CATEGORY, BRAND,
  UNIT_PRICE, COST_PRICE, ACTIVE, LAUNCH_DATE, ATTRIBUTES, SOURCE_FILE
)
FROM (
  SELECT
    $1:product_id::NUMBER(10, 0),
    $1:sku::VARCHAR,
    $1:product_name::VARCHAR,
    $1:category::VARCHAR,
    $1:brand::VARCHAR,
    $1:unit_price::NUMBER(10, 2),
    $1:cost_price::NUMBER(10, 2),
    $1:active::BOOLEAN,
    $1:launch_date::DATE,
    $1:attributes::VARIANT,
    METADATA$FILENAME
  FROM @BRONZE_PARQUET_STAGE
)
FILES = ('product_catalog_source.parquet')
ON_ERROR = 'ABORT_STATEMENT';

-- Preserve JSON documents in VARIANT while recording the file that supplied
-- each row. The stage file formats distinguish an array from JSON Lines.
COPY INTO BRONZE_WEB_EVENTS (EVENT, SOURCE_FILE)
FROM (
  SELECT $1, METADATA$FILENAME
  FROM @BRONZE_JSON_STAGE
)
FILES = ('events.json')
ON_ERROR = 'ABORT_STATEMENT';

-- device_readings.jsonl is deliberately reserved for the Snowpipe exercise
-- in 05_snowpipe.sql, rather than loaded with a second COPY INTO command.

SELECT 'BRONZE_CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM BRONZE_CUSTOMERS
UNION ALL
SELECT 'BRONZE_ORDERS', COUNT(*) FROM BRONZE_ORDERS
UNION ALL
SELECT 'BRONZE_PRODUCT_CATALOG', COUNT(*) FROM BRONZE_PRODUCT_CATALOG
UNION ALL
SELECT 'BRONZE_WEB_EVENTS', COUNT(*) FROM BRONZE_WEB_EVENTS
ORDER BY table_name;
