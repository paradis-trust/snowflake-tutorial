-- Module 4: Transformation and Serving
-- Expose gold data through standard, materialized, and secure views.
-- Run 02_full_refresh_transformation_patterns.sql first. Run 03 as well before
-- querying the dynamic-table-based secure view.

USE DATABASE LOAD_TRANSFORM_SERVE;

-- A standard view provides a stable, reusable business query without storing
-- its result. Keep currency in the grain: monetary values cannot be summed
-- correctly across currencies without an exchange-rate transformation.
CREATE OR REPLACE VIEW GOLD.VW_CUSTOMER_ORDER_SUMMARY AS
SELECT
  CUSTOMER_ID,
  FIRST_NAME,
  LAST_NAME,
  COUNTRY,
  CURRENCY,
  COUNT(ORDER_ID) AS ORDER_COUNT,
  SUM(NET_ORDER_TOTAL) AS NET_ORDER_TOTAL
FROM SILVER.SILVER_CUSTOMERS
LEFT JOIN SILVER.SILVER_ORDERS USING (CUSTOMER_ID)
WHERE IS_COMPLETED
GROUP BY CUSTOMER_ID, FIRST_NAME, LAST_NAME, COUNTRY, CURRENCY;

-- A materialized view stores a precomputed result. It queries one base table
-- only, which is a Snowflake materialized-view requirement. This feature
-- requires Enterprise Edition.
CREATE OR REPLACE MATERIALIZED VIEW GOLD.MV_ORDERS_BY_COUNTRY AS
SELECT
  SHIPPING_COUNTRY,
  CURRENCY,
  STATUS,
  COUNT(*) AS ORDER_COUNT,
  SUM(NET_ORDER_TOTAL) AS NET_ORDER_TOTAL
FROM SILVER.SILVER_ORDERS
GROUP BY SHIPPING_COUNTRY, CURRENCY, STATUS;

-- A secure view hides its definition from users who do not own it and exposes
-- only aggregated results, making it suitable for controlled sharing.
CREATE OR REPLACE SECURE VIEW GOLD.SECURE_DAILY_SALES AS
SELECT
  ORDER_DATE,
  SHIPPING_COUNTRY,
  CURRENCY,
  ORDER_COUNT,
  NET_ORDER_TOTAL
FROM GOLD.DT_DAILY_SALES;

SELECT * FROM GOLD.VW_CUSTOMER_ORDER_SUMMARY
ORDER BY NET_ORDER_TOTAL DESC, CUSTOMER_ID;

SELECT * FROM GOLD.MV_ORDERS_BY_COUNTRY
ORDER BY SHIPPING_COUNTRY, CURRENCY, STATUS;

SELECT * FROM GOLD.SECURE_DAILY_SALES
ORDER BY ORDER_DATE, SHIPPING_COUNTRY, CURRENCY;

SHOW VIEWS IN SCHEMA GOLD;
SHOW MATERIALIZED VIEWS IN SCHEMA GOLD;
