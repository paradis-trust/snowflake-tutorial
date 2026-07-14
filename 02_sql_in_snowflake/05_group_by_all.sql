-- Chapter 2: GROUP BY ALL in Snowflake
--
-- GROUP BY ALL groups by every SELECT item that is not an aggregate function.
-- It is useful when selecting several dimensions, because their names do not
-- need to be repeated in the GROUP BY clause.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA TPCH;

-- 1. Traditional GROUP BY: explicitly list every non-aggregate selected item.
SELECT
  O_ORDERSTATUS,
  O_ORDERPRIORITY,
  COUNT(*) AS order_count,
  ROUND(SUM(O_TOTALPRICE), 2) AS order_value
FROM ORDERS
GROUP BY O_ORDERSTATUS, O_ORDERPRIORITY
ORDER BY O_ORDERSTATUS, O_ORDERPRIORITY;

-- 2. The same result with GROUP BY ALL.
-- O_ORDERSTATUS and O_ORDERPRIORITY are inferred as grouping columns.
SELECT
  O_ORDERSTATUS,
  O_ORDERPRIORITY,
  COUNT(*) AS order_count,
  ROUND(SUM(O_TOTALPRICE), 2) AS order_value
FROM ORDERS
GROUP BY ALL
ORDER BY O_ORDERSTATUS, O_ORDERPRIORITY;

-- 3. GROUP BY ALL also works with expressions and their aliases.
SELECT
  DATE_TRUNC('MONTH', O_ORDERDATE) AS order_month,
  O_ORDERSTATUS AS order_status,
  COUNT(*) AS order_count,
  ROUND(AVG(O_TOTALPRICE), 2) AS average_order_value
FROM ORDERS
GROUP BY ALL
ORDER BY order_month, order_status;

-- 4. Use it after joins to group by descriptive dimensions.
SELECT
  N.N_NAME AS nation,
  C.C_MKTSEGMENT AS market_segment,
  COUNT(*) AS order_count,
  ROUND(SUM(O.O_TOTALPRICE), 2) AS order_value
FROM ORDERS AS O
INNER JOIN CUSTOMER AS C
  ON O.O_CUSTKEY = C.C_CUSTKEY
INNER JOIN NATION AS N
  ON C.C_NATIONKEY = N.N_NATIONKEY
GROUP BY ALL
ORDER BY order_value DESC;

-- 5. Be deliberate about the result grain.
-- Adding O_ORDERPRIORITY below creates more, smaller groups than example 3.
SELECT
  DATE_TRUNC('MONTH', O_ORDERDATE) AS order_month,
  O_ORDERSTATUS AS order_status,
  O_ORDERPRIORITY AS order_priority,
  COUNT(*) AS order_count
FROM ORDERS
GROUP BY ALL
ORDER BY order_month, order_status, order_priority;

-- 6. When every selected item is an aggregate, GROUP BY ALL is equivalent to
-- omitting GROUP BY. This is valid, but omitting it is usually clearer.
SELECT
  COUNT(*) AS order_count,
  ROUND(SUM(O_TOTALPRICE), 2) AS total_order_value
FROM ORDERS
GROUP BY ALL;

-- Avoid SELECT * with GROUP BY ALL in analytics: it groups by every selected
-- source column, which usually produces an unnecessarily detailed result.
