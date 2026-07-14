-- Chapter 2: QUALIFY in Snowflake
--
-- QUALIFY filters the result of a window function. It fills the same role that
-- a WHERE clause cannot: WHERE runs before window functions are calculated.
-- It is evaluated after window functions and before the final ORDER BY.
--
-- QUALIFY requires at least one window function in the SELECT list or QUALIFY
-- predicate. It avoids an otherwise necessary subquery or CTE.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA TPCH;

-- 1. Simplest case: keep the ten most expensive orders in the whole table.
SELECT
  O_ORDERKEY,
  O_CUSTKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  ROW_NUMBER() OVER (ORDER BY O_TOTALPRICE DESC) AS price_position
FROM ORDERS
QUALIFY price_position <= 10
ORDER BY price_position;

-- Note that here the query is similar to a simple LIMIT
SELECT
  O_ORDERKEY,
  O_CUSTKEY,
  O_ORDERDATE,
  O_TOTALPRICE
FROM ORDERS
ORDER BY O_TOTALPRICE DESC
LIMIT 10;

-- 2. Keep the latest order for each of 20 customers.
-- ROW_NUMBER guarantees one row per customer, even when dates are tied.
WITH selected_customers AS (
  SELECT C_CUSTKEY
  FROM CUSTOMER
  ORDER BY C_CUSTKEY
  LIMIT 20
)
SELECT
  O.O_CUSTKEY,
  O.O_ORDERKEY,
  O.O_ORDERDATE,
  O.O_TOTALPRICE,
  ROW_NUMBER() OVER (
    PARTITION BY O.O_CUSTKEY
    ORDER BY O.O_ORDERDATE DESC, O.O_ORDERKEY DESC
  ) AS latest_order_position
FROM ORDERS AS O
INNER JOIN selected_customers AS C
  ON O.O_CUSTKEY = C.C_CUSTKEY
QUALIFY latest_order_position = 1
ORDER BY O.O_CUSTKEY;

-- 3. Find the three most valuable orders within each nation.
-- RANK keeps ties: if two orders have the same value, they get the same rank.
SELECT
  N.N_NAME AS nation,
  O.O_ORDERKEY,
  O.O_TOTALPRICE,
  RANK() OVER (
    PARTITION BY N.N_NAME
    ORDER BY O.O_TOTALPRICE DESC
  ) AS order_value_rank
FROM ORDERS AS O
INNER JOIN CUSTOMER AS C
  ON O.O_CUSTKEY = C.C_CUSTKEY
INNER JOIN NATION AS N
  ON C.C_NATIONKEY = N.N_NATIONKEY
QUALIFY order_value_rank <= 3
ORDER BY nation, order_value_rank, O_ORDERKEY;

-- 4. Select one preferred supplier for every part.
-- This is a common "one row per group" pattern. The lowest supply cost wins;
-- PS_SUPPKEY breaks a tie deterministically.
SELECT
  PS_PARTKEY,
  PS_SUPPKEY,
  PS_SUPPLYCOST,
  ROW_NUMBER() OVER (
    PARTITION BY PS_PARTKEY
    ORDER BY PS_SUPPLYCOST, PS_SUPPKEY
  ) AS supplier_preference
FROM PARTSUPP
QUALIFY supplier_preference = 1
ORDER BY PS_PARTKEY
LIMIT 20;

-- 5. Combine several window functions: show the first three orders for each
-- of 20 customers, with a running total and the prior order's value.
WITH selected_customers AS (
  SELECT C_CUSTKEY
  FROM CUSTOMER
  ORDER BY C_CUSTKEY
  LIMIT 20
)
SELECT
  O.O_CUSTKEY,
  O.O_ORDERDATE,
  O.O_ORDERKEY,
  O.O_TOTALPRICE,
  SUM(O.O_TOTALPRICE) OVER (
    PARTITION BY O.O_CUSTKEY
    ORDER BY O.O_ORDERDATE, O.O_ORDERKEY
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- deterministic SUM behavior"
  ) AS running_order_value,
  LAG(O.O_TOTALPRICE) OVER (
    PARTITION BY O.O_CUSTKEY
    ORDER BY O.O_ORDERDATE, O.O_ORDERKEY
  ) AS previous_order_value,
  ROW_NUMBER() OVER (
    PARTITION BY O.O_CUSTKEY
    ORDER BY O.O_ORDERDATE, O.O_ORDERKEY
  ) AS order_number
FROM ORDERS AS O
INNER JOIN selected_customers AS C
  ON O.O_CUSTKEY = C.C_CUSTKEY
QUALIFY order_number <= 3
ORDER BY O.O_CUSTKEY, O.O_ORDERDATE, O.O_ORDERKEY;
