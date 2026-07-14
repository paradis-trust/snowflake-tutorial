-- Chapter 2: GENERATOR() table function
--
-- GENERATOR produces a requested number of empty rows. Add expressions in
-- SELECT to give those rows useful values. Invoke it through TABLE(...).

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA TPCH;

-- 1. Generate ten rows and number them from 1 to 10.
-- ROW_NUMBER is gap-free, unlike a sequence that can have gaps at scale.
SELECT
  ROW_NUMBER() OVER (ORDER BY SEQ4()) AS row_number
FROM TABLE(GENERATOR(ROWCOUNT => 10));

-- 2. Create a seven-day calendar scaffold.
WITH day_numbers AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
  FROM TABLE(GENERATOR(ROWCOUNT => 7))
)
SELECT
  DATEADD('DAY', day_offset, DATE '2026-01-01') AS calendar_date,
  DAYNAME(DATEADD('DAY', day_offset, DATE '2026-01-01')) AS day_name
FROM day_numbers
ORDER BY calendar_date;

-- 3. Create simple synthetic daily sales values.
-- RANDOM() makes the values different on each execution.
WITH day_numbers AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS day_offset
  FROM TABLE(GENERATOR(ROWCOUNT => 14))
)
SELECT
  DATEADD('DAY', day_offset, DATE '2026-01-01') AS sales_date,
  UNIFORM(100, 1000, RANDOM()) AS simulated_sales
FROM day_numbers
ORDER BY sales_date;

-- 4. Use a generated calendar to expose dates with no orders.
-- The TPC-H data covers 1992-1998, so this example uses December 1992.
WITH calendar AS (
  SELECT DATEADD(
    'DAY',
    ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1,
    DATE '1991-12-20'
  ) AS calendar_date
  FROM TABLE(GENERATOR(ROWCOUNT => 31))
),
daily_orders AS (
  SELECT
    O_ORDERDATE,
    COUNT(*) AS order_count,
    SUM(O_TOTALPRICE) AS order_value
  FROM ORDERS
  WHERE O_ORDERDATE BETWEEN DATE '1991-12-20' AND DATE '1992-01-20'
  GROUP BY O_ORDERDATE
)
SELECT
  C.calendar_date,
  COALESCE(D.order_count, 0) AS order_count,
  COALESCE(D.order_value, 0) AS order_value
FROM calendar AS C
LEFT JOIN daily_orders AS D
  ON C.calendar_date = D.O_ORDERDATE
ORDER BY C.calendar_date;

-- ROWCOUNT must be a non-negative integer constant. GENERATOR() with no
-- ROWCOUNT or TIMELIMIT produces zero rows. TIMELIMIT is useful for benchmark
-- experiments, but its number of generated rows is intentionally variable.
