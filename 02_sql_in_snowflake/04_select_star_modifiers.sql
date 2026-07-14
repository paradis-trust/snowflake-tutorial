-- Chapter 2: SELECT * modifiers in Snowflake
--
-- Snowflake extends SELECT * with four useful modifiers:
--   EXCLUDE: remove named columns from the result.
--   ILIKE:   keep only columns whose names match a pattern.
--   REPLACE: replace a selected column's value with an expression.
--   RENAME:  change a selected column's output name.
--
-- When combined, their required order is:
--   ILIKE or EXCLUDE, then REPLACE, then RENAME.
-- ILIKE and EXCLUDE cannot be used together.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA TPCH;

-- 1. The baseline: select every column in ORDERS.
SELECT *
FROM ORDERS
LIMIT 10;

-- 2. EXCLUDE one column that is not useful for this analysis.
SELECT * EXCLUDE O_COMMENT
FROM ORDERS
LIMIT 10;

-- 3. EXCLUDE several columns.
SELECT * EXCLUDE (O_COMMENT, O_CLERK)
FROM ORDERS
LIMIT 10;

-- 4. ILIKE selects columns by *column name*, case-insensitively.
-- This returns L_SHIPDATE, L_COMMITDATE, and L_RECEIPTDATE.
SELECT * ILIKE '%DATE%'
FROM LINEITEM
LIMIT 10;

-- 5. REPLACE changes a selected column's value but retains its position.
-- Here, O_TOTALPRICE is shown with a simulated 10% increase.
SELECT * REPLACE (
  ROUND(O_TOTALPRICE * 1.10, 2) AS O_TOTALPRICE
)
FROM ORDERS
LIMIT 10;

-- 6. RENAME changes output column names without changing the source table.
SELECT * RENAME (
  O_ORDERKEY AS order_id,
  O_CUSTKEY AS customer_id,
  O_TOTALPRICE AS order_value
)
FROM ORDERS
LIMIT 10;

-- 7. Combine EXCLUDE, REPLACE, and RENAME.
-- First remove unneeded columns, then replace the value, then rename it.
SELECT *
  EXCLUDE (O_COMMENT, O_CLERK)
  REPLACE (ROUND(O_TOTALPRICE * 1.10, 2) AS O_TOTALPRICE)
  RENAME (
    O_ORDERKEY AS order_id,
    O_CUSTKEY AS customer_id,
    O_TOTALPRICE AS simulated_order_value
  )
FROM ORDERS
LIMIT 10;

-- 8. Use a qualified * after a join to return all columns from one table.
-- Qualifying the star avoids returning every column from both tables.
SELECT O.*
  EXCLUDE (O_COMMENT, O_CLERK)
  RENAME (
    O_ORDERKEY AS order_id,
    O_CUSTKEY AS customer_id,
    O_TOTALPRICE AS order_value
  ),
  C.C_NAME AS customer_name,
  C.C_MKTSEGMENT AS market_segment
FROM ORDERS AS O
INNER JOIN CUSTOMER AS C
  ON O.O_CUSTKEY = C.C_CUSTKEY
LIMIT 10;
