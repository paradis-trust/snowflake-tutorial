-- Chapter 2: SQL in Snowflake
-- Basic analytical SQL examples using the writable TPC-H data.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA TPCH;

-- 1. Inspect a table: SELECT, a column list, aliases, and LIMIT.
SELECT
  C_CUSTKEY AS customer_id,
  C_NAME AS customer_name,
  C_MKTSEGMENT AS market_segment
FROM CUSTOMER
LIMIT 10;

-- 2. Filter rows with WHERE, comparisons, AND, IN, and LIKE.
SELECT
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  O_ORDERPRIORITY
FROM ORDERS
WHERE O_ORDERDATE BETWEEN '1995-01-01' AND '1995-12-31'
  AND O_ORDERPRIORITY IN ('1-URGENT', '2-HIGH')
  AND O_ORDERSTATUS = 'O'
ORDER BY O_TOTALPRICE DESC
LIMIT 20;

SELECT P_PARTKEY, P_NAME, P_TYPE
FROM PART
WHERE P_NAME LIKE '%green%'
LIMIT 20;

-- 3. Return distinct values.
SELECT DISTINCT C_MKTSEGMENT AS market_segment
FROM CUSTOMER
ORDER BY market_segment;

-- 4. Calculate a metric and derive a category with CASE.
SELECT
  L_ORDERKEY,
  L_LINENUMBER,
  L_EXTENDEDPRICE,
  L_DISCOUNT,
  ROUND(L_EXTENDEDPRICE * (1 - L_DISCOUNT), 2) AS net_revenue,
  CASE
    WHEN L_DISCOUNT >= 0.07 THEN 'high discount'
    WHEN L_DISCOUNT > 0 THEN 'discounted'
    ELSE 'full price'
  END AS discount_band
FROM LINEITEM
LIMIT 20;

-- 5. Replace a possible NULL with a meaningful default using COALESCE.
SELECT
  S_NAME AS supplier_name,
  COALESCE(S_ACCTBAL, 0) AS account_balance
FROM SUPPLIER
ORDER BY account_balance DESC
LIMIT 10;

-- 6. Aggregate the whole table with COUNT, SUM, AVG, MIN, and MAX.
SELECT
  COUNT(*) AS line_item_count,
  COUNT(DISTINCT L_ORDERKEY) AS order_count,
  ROUND(SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)), 2) AS total_net_revenue,
  ROUND(AVG(L_QUANTITY), 2) AS average_quantity,
  MIN(L_SHIPDATE) AS first_ship_date,
  MAX(L_SHIPDATE) AS last_ship_date
FROM LINEITEM;

-- 7. Aggregate by a dimension with GROUP BY, then filter groups with HAVING.
SELECT
  L_RETURNFLAG AS return_flag,
  COUNT(*) AS line_item_count,
  ROUND(SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)), 2) AS net_revenue
FROM LINEITEM
GROUP BY L_RETURNFLAG
HAVING SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) > 1000000
ORDER BY net_revenue DESC;

-- 8. Work with dates: group revenue by order month.
SELECT
  DATE_TRUNC('MONTH', O_ORDERDATE) AS order_month,
  COUNT(*) AS order_count,
  ROUND(SUM(O_TOTALPRICE), 2) AS order_value
FROM ORDERS
GROUP BY order_month
ORDER BY order_month;

SELECT
  L_ORDERKEY,
  L_SHIPDATE,
  L_RECEIPTDATE,
  DATEDIFF('DAY', L_SHIPDATE, L_RECEIPTDATE) AS shipping_days
FROM LINEITEM
ORDER BY shipping_days DESC
LIMIT 20;

-- 9. Combine related tables with INNER JOIN.
SELECT
  N.N_NAME AS nation,
  COUNT(*) AS order_count,
  ROUND(SUM(O.O_TOTALPRICE), 2) AS order_value
FROM ORDERS AS O
INNER JOIN CUSTOMER AS C
  ON O.O_CUSTKEY = C.C_CUSTKEY
INNER JOIN NATION AS N
  ON C.C_NATIONKEY = N.N_NATIONKEY
GROUP BY nation
ORDER BY order_value DESC;

-- 10. Keep all rows from the left table with LEFT JOIN.
SELECT
  P.P_PARTKEY,
  P.P_NAME,
  COUNT(PS.PS_SUPPKEY) AS supplier_count
FROM PART AS P
LEFT JOIN PARTSUPP AS PS
  ON P.P_PARTKEY = PS.PS_PARTKEY
GROUP BY P.P_PARTKEY, P.P_NAME
ORDER BY supplier_count DESC, P.P_PARTKEY
LIMIT 20;

-- 11. Use a CTE to give a multi-step analysis a name.
WITH customer_revenue AS (
  SELECT
    O.O_CUSTKEY,
    SUM(L.L_EXTENDEDPRICE * (1 - L.L_DISCOUNT)) AS net_revenue
  FROM ORDERS AS O
  INNER JOIN LINEITEM AS L
    ON O.O_ORDERKEY = L.L_ORDERKEY
  GROUP BY O.O_CUSTKEY
)
SELECT
  C.C_NAME AS customer_name,
  ROUND(CR.net_revenue, 2) AS net_revenue
FROM customer_revenue AS CR
INNER JOIN CUSTOMER AS C
  ON CR.O_CUSTKEY = C.C_CUSTKEY
ORDER BY net_revenue DESC
LIMIT 10;

-- 12. Filter with a subquery: customers whose balance is above their nation's average.
SELECT
  C.C_NAME AS customer_name,
  N.N_NAME AS nation,
  C.C_ACCTBAL AS account_balance
FROM CUSTOMER AS C
INNER JOIN NATION AS N
  ON C.C_NATIONKEY = N.N_NATIONKEY
WHERE C.C_ACCTBAL > (
  SELECT AVG(C2.C_ACCTBAL)
  FROM CUSTOMER AS C2
  WHERE C2.C_NATIONKEY = C.C_NATIONKEY
)
ORDER BY account_balance DESC
LIMIT 20;

-- 13. Stack compatible results with UNION ALL.
SELECT 'customer' AS entity_type, C_NAME AS entity_name
FROM CUSTOMER
WHERE C_NATIONKEY = 0
UNION ALL
SELECT 'supplier' AS entity_type, S_NAME AS entity_name
FROM SUPPLIER
WHERE S_NATIONKEY = 0
ORDER BY entity_type, entity_name
LIMIT 20;

-- 14. Rank customers within each nation with a window function.
SELECT
  N.N_NAME AS nation,
  C.C_NAME AS customer_name,
  C.C_ACCTBAL AS account_balance,
  RANK() OVER (
    PARTITION BY N.N_NAME
    ORDER BY C.C_ACCTBAL DESC
  ) AS balance_rank
FROM CUSTOMER AS C
INNER JOIN NATION AS N
  ON C.C_NATIONKEY = N.N_NATIONKEY
QUALIFY balance_rank <= 3
ORDER BY nation, balance_rank, customer_name;

-- 15. Save a reusable analytical query as a view.
CREATE OR REPLACE VIEW MONTHLY_ORDER_SUMMARY AS
SELECT
  DATE_TRUNC('MONTH', O_ORDERDATE) AS order_month,
  COUNT(*) AS order_count,
  SUM(O_TOTALPRICE) AS order_value
FROM ORDERS
GROUP BY order_month;

SELECT *
FROM MONTHLY_ORDER_SUMMARY
ORDER BY order_month;
