-- Chapter 2: Semi-structured data workshop
-- Use FLATTEN to turn JSON arrays and objects into rows.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA SEMI_STRUCTURED;

-- 1. Flatten the items array. One order becomes one row per item.
SELECT
  O.SRC:order_id::VARCHAR AS order_id,
  I.INDEX AS item_position,
  I.VALUE:sku::VARCHAR AS sku,
  I.VALUE:name::VARCHAR AS item_name,
  I.VALUE:quantity::NUMBER AS quantity,
  I.VALUE:unit_price::NUMBER(10, 2) AS unit_price
FROM RAW_ORDERS AS O,
LATERAL FLATTEN(INPUT => O.SRC:items) AS I
ORDER BY order_id, item_position;

-- 2. OUTER => TRUE keeps orders whose items array is empty.
-- The generated item columns are NULL for WEB-1003.
SELECT
  O.SRC:order_id::VARCHAR AS order_id,
  I.INDEX AS item_position,
  I.VALUE:sku::VARCHAR AS sku
FROM RAW_ORDERS AS O,
LATERAL FLATTEN(INPUT => O.SRC:items, OUTER => TRUE) AS I
ORDER BY order_id, item_position;

-- 3. Flatten an object to return its key/value pairs.
SELECT
  O.SRC:order_id::VARCHAR AS order_id,
  I.VALUE:sku::VARCHAR AS sku,
  A.KEY::VARCHAR AS attribute_name,
  A.VALUE AS attribute_value
FROM RAW_ORDERS AS O,
LATERAL FLATTEN(INPUT => O.SRC:items) AS I,
LATERAL FLATTEN(INPUT => I.VALUE:attributes) AS A
ORDER BY order_id, sku, attribute_name;

-- 4. Flatten the tags array and filter its scalar values.
SELECT
  O.SRC:order_id::VARCHAR AS order_id,
  T.VALUE::VARCHAR AS tag
FROM RAW_ORDERS AS O,
LATERAL FLATTEN(INPUT => O.SRC:tags) AS T
WHERE T.VALUE::VARCHAR LIKE 'campaign%'
ORDER BY order_id;

-- 5. Flatten customer addresses from a different JSON document.
SELECT
  C.SRC:customer_id::VARCHAR AS customer_id,
  C.SRC:name::VARCHAR AS customer_name,
  A.VALUE:type::VARCHAR AS address_type,
  A.VALUE:city::VARCHAR AS city,
  A.VALUE:country::VARCHAR AS country
FROM RAW_CUSTOMERS AS C,
LATERAL FLATTEN(INPUT => C.SRC:addresses) AS A
ORDER BY customer_id, address_type;

-- 6. RECURSIVE => TRUE is useful for exploring an unfamiliar nested document.
-- Filter out container values so the result focuses on leaf paths.
SELECT
  E.SRC:event_id::VARCHAR AS event_id,
  F.PATH AS json_path,
  F.KEY::VARCHAR AS key_name,
  TYPEOF(F.VALUE) AS value_type,
  F.VALUE AS value
FROM RAW_EVENTS AS E,
LATERAL FLATTEN(INPUT => E.SRC, RECURSIVE => TRUE) AS F
WHERE TYPEOF(F.VALUE) NOT IN ('OBJECT', 'ARRAY')
ORDER BY event_id, json_path;

-- 7. Materialize a relational order-item table for repeated analytics.
-- Keep the raw JSON table as the source of truth; this table is a convenient
-- typed representation of the item array.
CREATE OR REPLACE TABLE ORDER_ITEMS AS
SELECT
  O.SRC:order_id::VARCHAR AS order_id,
  O.SRC:order_date::DATE AS order_date,
  O.SRC:customer.id::VARCHAR AS customer_id,
  O.SRC:shipping_address.country::VARCHAR AS country,
  I.INDEX::NUMBER AS item_position,
  I.VALUE:sku::VARCHAR AS sku,
  I.VALUE:name::VARCHAR AS item_name,
  I.VALUE:quantity::NUMBER AS quantity,
  I.VALUE:unit_price::NUMBER(10, 2) AS unit_price,
  I.VALUE:quantity::NUMBER * I.VALUE:unit_price::NUMBER(10, 2) AS line_amount
FROM RAW_ORDERS AS O,
LATERAL FLATTEN(INPUT => O.SRC:items) AS I;

-- 8. The flattened table can now be queried like a normal analytical table.
SELECT
  country,
  COUNT(*) AS line_count,
  ROUND(SUM(line_amount), 2) AS revenue
FROM ORDER_ITEMS
GROUP BY country
ORDER BY revenue DESC;
