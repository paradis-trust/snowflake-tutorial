-- Chapter 2: Semi-structured data workshop
-- Query JSON documents held in a VARIANT column without flattening them.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA SEMI_STRUCTURED;

-- 1. Inspect the original JSON document and its load metadata.
SELECT SRC, SOURCE_FILE, LOADED_AT
FROM RAW_ORDERS;

-- 2. Use colon and dot notation to traverse nested JSON objects.
-- Path extraction returns VARIANT; cast the result for normal SQL operations.
SELECT
  SRC:order_id::VARCHAR AS order_id,
  SRC:order_date::DATE AS order_date,
  SRC:customer.id::VARCHAR AS customer_id,
  SRC:customer.name::VARCHAR AS customer_name,
  SRC:customer.contact.email::VARCHAR AS email,
  SRC:shipping_address.city::VARCHAR AS city
FROM RAW_ORDERS
ORDER BY order_id;

-- 3. Quote a JSON key that is not a regular SQL identifier.
-- JSON key names are case-sensitive; "shipping-method" is not the same as
-- "Shipping-Method".
SELECT
  SRC:order_id::VARCHAR AS order_id,
  SRC:"shipping-method"::VARCHAR AS shipping_method
FROM RAW_ORDERS
ORDER BY order_id;

-- 4. Access an array element by its zero-based index.
SELECT
  SRC:order_id::VARCHAR AS order_id,
  SRC:items[0].sku::VARCHAR AS first_item_sku,
  SRC:items[0].quantity::NUMBER AS first_item_quantity
FROM RAW_ORDERS
ORDER BY order_id;

-- 5. GET_PATH is useful when a path is supplied as a string.
-- It is equivalent to the path notation used above for this fixed path.
SELECT
  SRC:order_id::VARCHAR AS order_id,
  GET_PATH(SRC, 'customer.contact.email')::VARCHAR AS email
FROM RAW_ORDERS
ORDER BY order_id;

-- 6. Filter on a JSON value after casting it to the desired SQL type.
SELECT
  SRC:order_id::VARCHAR AS order_id,
  SRC:customer.name::VARCHAR AS customer_name,
  SRC:customer.contact.marketing_opt_in::BOOLEAN AS marketing_opt_in
FROM RAW_ORDERS
WHERE SRC:customer.contact.marketing_opt_in::BOOLEAN = TRUE;

-- 7. Distinguish JSON null from a missing key.
-- WEB-1002 has a JSON null discount; WEB-1003 has no discount key.
SELECT
  SRC:order_id::VARCHAR AS order_id,
  SRC:discount AS raw_discount,
  IS_NULL_VALUE(SRC:discount) AS is_json_null,
  SRC:discount IS NULL AS is_sql_null
FROM RAW_ORDERS
ORDER BY order_id;

-- 8. TYPEOF helps explore a document before deciding how to query it.
SELECT
  SRC:order_id::VARCHAR AS order_id,
  TYPEOF(SRC:customer) AS customer_type,
  TYPEOF(SRC:items) AS items_type,
  TYPEOF(SRC:items[0].unit_price) AS unit_price_type
FROM RAW_ORDERS
ORDER BY order_id;

-- 9. OBJECT_KEYS returns the keys in an object as an array.
SELECT
  SRC:order_id::VARCHAR AS order_id,
  OBJECT_KEYS(SRC:customer) AS customer_keys
FROM RAW_ORDERS
ORDER BY order_id;

-- 10. JSON timestamps are strings in VARIANT. Cast them before time analysis.
SELECT
  SRC:event_id::VARCHAR AS event_id,
  SRC:event_type::VARCHAR AS event_type,
  SRC:event_at::TIMESTAMP_TZ AS event_at,
  SRC:context.device.type::VARCHAR AS device_type
FROM RAW_EVENTS
ORDER BY event_at;
