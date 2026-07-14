-- Chapter 2: Semi-structured data workshop
-- Upload the repository JSON files to the internal stage, then load them.
--
-- PUT is a client-side command. Run the three PUT statements with SnowSQL,
-- Snowflake CLI, or another supported client, not a Snowsight worksheet.
-- Replace <repo-root> with this repository's absolute path.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA SEMI_STRUCTURED;

PUT file://<repo-root>/02_sql_in_snowflake/08_semi_structured_data/orders.json
  @JSON_WORKSHOP_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

PUT file://<repo-root>/02_sql_in_snowflake/08_semi_structured_data/customers.json
  @JSON_WORKSHOP_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

PUT file://<repo-root>/02_sql_in_snowflake/08_semi_structured_data/events.json
  @JSON_WORKSHOP_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

LIST @JSON_WORKSHOP_STAGE;

-- Each COPY statement loads the objects from one JSON array into a VARIANT
-- column and records the staged filename alongside the source document.
COPY INTO RAW_ORDERS (SRC, SOURCE_FILE)
FROM (
  SELECT $1, METADATA$FILENAME
  FROM @JSON_WORKSHOP_STAGE
)
FILES = ('orders.json')
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO RAW_CUSTOMERS (SRC, SOURCE_FILE)
FROM (
  SELECT $1, METADATA$FILENAME
  FROM @JSON_WORKSHOP_STAGE
)
FILES = ('customers.json')
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO RAW_EVENTS (SRC, SOURCE_FILE)
FROM (
  SELECT $1, METADATA$FILENAME
  FROM @JSON_WORKSHOP_STAGE
)
FILES = ('events.json')
ON_ERROR = 'ABORT_STATEMENT';

SELECT 'RAW_ORDERS' AS table_name, COUNT(*) AS row_count FROM RAW_ORDERS
UNION ALL
SELECT 'RAW_CUSTOMERS', COUNT(*) FROM RAW_CUSTOMERS
UNION ALL
SELECT 'RAW_EVENTS', COUNT(*) FROM RAW_EVENTS
ORDER BY table_name;

-- To deliberately reload a file during the workshop, first TRUNCATE its raw
-- table, then add FORCE = TRUE to that table's COPY INTO statement.
