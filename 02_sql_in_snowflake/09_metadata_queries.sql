-- Chapter 2: Metadata queries
--
-- INFORMATION_SCHEMA: metadata for the current database and table functions
-- that return recent operational data.
-- SNOWFLAKE.ACCOUNT_USAGE: account-wide historical views for governance,
-- monitoring, and cost analysis. These views have a refresh delay.
--
-- ACCOUNT_USAGE access: use ACCOUNTADMIN, or a role with the appropriate
-- SNOWFLAKE database role / imported privileges. Each query below selects only
-- the needed columns; avoid SELECT * from Snowflake-provided metadata views.

-- ---------------------------------------------------------------------------
-- INFORMATION_SCHEMA: objects the current role can see in this database.
-- ---------------------------------------------------------------------------

-- 1. List tables, their estimated row counts, and their current size.
SELECT
  TABLE_SCHEMA,
  TABLE_NAME,
  TABLE_TYPE,
  ROW_COUNT,
  BYTES,
  CREATED,
  LAST_ALTERED
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('TPCH', 'SEMI_STRUCTURED')
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- 2. Document a table's columns and data types.
SELECT
  TABLE_SCHEMA,
  TABLE_NAME,
  ORDINAL_POSITION,
  COLUMN_NAME,
  DATA_TYPE,
  IS_NULLABLE,
  COLUMN_DEFAULT,
  COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'SEMI_STRUCTURED'
  AND TABLE_NAME IN ('RAW_ORDERS', 'ORDER_ITEMS')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 3. List views created in the tutorial database.
SELECT
  TABLE_SCHEMA,
  TABLE_NAME AS view_name,
  VIEW_DEFINITION,
  CREATED,
  LAST_ALTERED
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_SCHEMA, view_name;

-- 4. Recent query history from the Information Schema table function.
-- This is useful immediately after running a query. It is limited to recent
-- history (up to seven days), unlike the longer-retention ACCOUNT_USAGE view.
SELECT
  QUERY_ID,
  QUERY_TYPE,
  EXECUTION_STATUS,
  START_TIME,
  TOTAL_ELAPSED_TIME / 1000 AS elapsed_seconds,
  BYTES_SCANNED,
  QUERY_TEXT
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
  END_TIME_RANGE_START => DATEADD('HOUR', -1, CURRENT_TIMESTAMP()),
  END_TIME_RANGE_END => CURRENT_TIMESTAMP(),
  RESULT_LIMIT => 10
))
ORDER BY START_TIME DESC;

-- ---------------------------------------------------------------------------
-- ACCOUNT_USAGE: account-wide historical metadata and usage.
-- These views can take time to refresh; query history can be delayed by up to
-- 45 minutes, and warehouse load history by up to 3 hours.
-- ---------------------------------------------------------------------------

-- 5. Account-wide query history: find the slowest successful queries in the
-- last seven days. Filter on START_TIME to keep the view scan focused.
SELECT
  QUERY_ID,
  USER_NAME,
  WAREHOUSE_NAME,
  DATABASE_NAME,
  SCHEMA_NAME,
  START_TIME,
  ROUND(TOTAL_ELAPSED_TIME / 1000, 2) AS elapsed_seconds,
  BYTES_SCANNED,
  PERCENTAGE_SCANNED_FROM_CACHE,
  QUERY_TEXT
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
  AND EXECUTION_STATUS = 'SUCCESS'
  AND USER_NAME <> 'SYSTEM'
ORDER BY TOTAL_ELAPSED_TIME DESC
LIMIT 20;

-- 6. Warehouse-credit consumption by day for the last 30 days.
SELECT
  WAREHOUSE_NAME,
  DATE_TRUNC('DAY', START_TIME) AS usage_date,
  ROUND(SUM(CREDITS_USED), 2) AS credits_used,
  ROUND(SUM(CREDITS_USED_COMPUTE), 2) AS compute_credits,
  ROUND(SUM(CREDITS_USED_CLOUD_SERVICES), 2) AS cloud_services_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('DAY', -30, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME, usage_date
ORDER BY usage_date DESC, credits_used DESC;

-- 7. Storage components for the tutorial database's tables.
-- Divide by POWER(1024, 3) to display bytes as GiB.
SELECT
  TABLE_SCHEMA,
  TABLE_NAME,
  ROUND(ACTIVE_BYTES / POWER(1024, 3), 3) AS active_gib,
  ROUND(TIME_TRAVEL_BYTES / POWER(1024, 3), 3) AS time_travel_gib,
  ROUND(FAILSAFE_BYTES / POWER(1024, 3), 3) AS failsafe_gib,
  ROUND(RETAINED_FOR_CLONE_BYTES / POWER(1024, 3), 3) AS clone_retained_gib
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
WHERE TABLE_CATALOG = 'SQL_IN_SNOWFLAKE'
  AND TABLE_SCHEMA IN ('TPCH', 'SEMI_STRUCTURED')
  AND TABLE_DROPPED IS NULL
ORDER BY active_gib DESC, TABLE_SCHEMA, TABLE_NAME;

-- 8. Review the JSON workshop's COPY load history.
SELECT
  TABLE_NAME,
  FILE_NAME,
  LAST_LOAD_TIME,
  STATUS,
  ROW_COUNT,
  ROW_PARSED,
  FIRST_ERROR_MESSAGE,
  CATALOG_NAME
FROM SNOWFLAKE.ACCOUNT_USAGE.LOAD_HISTORY
WHERE CATALOG_NAME = 'SQL_IN_SNOWFLAKE'
  AND SCHEMA_NAME = 'SEMI_STRUCTURED'
  AND LAST_LOAD_TIME >= DATEADD('DAY', -30, CURRENT_TIMESTAMP())
ORDER BY LAST_LOAD_TIME DESC;
