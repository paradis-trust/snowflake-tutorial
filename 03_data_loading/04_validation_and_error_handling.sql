-- Module 3: Data Loading
-- Validate a bad file, then compare common ON_ERROR behaviours.
-- This script uses a temporary table so the bronze order table remains clean.

USE DATABASE DATA_LOADING;
USE SCHEMA BRONZE;

CREATE OR REPLACE TEMPORARY TABLE ORDER_LOAD_ERROR_DEMO
  LIKE BRONZE_ORDERS;

-- Validation checks a file but never inserts rows. RETURN_ERRORS is useful for
-- a quick check; RETURN_ALL_ERRORS reports every parsing and conversion issue.
COPY INTO ORDER_LOAD_ERROR_DEMO (
  ORDER_ID, CUSTOMER_ID, ORDER_DATE, STATUS, SALES_CHANNEL,
  CURRENCY, ORDER_TOTAL, DISCOUNT_AMOUNT, SHIPPING_CITY, SHIPPING_COUNTRY
)
FROM @BRONZE_CSV_STAGE
FILES = ('malformed_orders.csv')
VALIDATION_MODE = 'RETURN_ERRORS';

COPY INTO ORDER_LOAD_ERROR_DEMO (
  ORDER_ID, CUSTOMER_ID, ORDER_DATE, STATUS, SALES_CHANNEL,
  CURRENCY, ORDER_TOTAL, DISCOUNT_AMOUNT, SHIPPING_CITY, SHIPPING_COUNTRY
)
FROM @BRONZE_CSV_STAGE
FILES = ('malformed_orders.csv')
VALIDATION_MODE = 'RETURN_ALL_ERRORS';

-- CONTINUE loads valid rows and records the problematic ones in load metadata.
COPY INTO ORDER_LOAD_ERROR_DEMO (
  ORDER_ID, CUSTOMER_ID, ORDER_DATE, STATUS, SALES_CHANNEL,
  CURRENCY, ORDER_TOTAL, DISCOUNT_AMOUNT, SHIPPING_CITY, SHIPPING_COUNTRY
)
FROM @BRONZE_CSV_STAGE
FILES = ('malformed_orders.csv')
ON_ERROR = 'CONTINUE';

-- Run immediately after the previous COPY. _last refers to the most recent
-- COPY in this session and returns the rejected records and error details.
SELECT *
FROM TABLE(VALIDATE(ORDER_LOAD_ERROR_DEMO, JOB_ID => '_last'));

-- VALIDATE returns a query result that includes REJECTED_RECORD. Capture that
-- result and write it to the rejected-files stage for later inspection.
SET rejected_records_query_id = LAST_QUERY_ID();

COPY INTO @BRONZE_REJECTED_FILES_STAGE/validation/
FROM (
  SELECT REJECTED_RECORD
  FROM TABLE(RESULT_SCAN($rejected_records_query_id))
)
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"')
HEADER = TRUE
SINGLE = TRUE
OVERWRITE = TRUE;

LIST @BRONZE_REJECTED_FILES_STAGE/validation/;

SELECT * FROM ORDER_LOAD_ERROR_DEMO ORDER BY ORDER_ID;

TRUNCATE TABLE ORDER_LOAD_ERROR_DEMO;

-- SKIP_FILE leaves the target empty when a file has any error. This is a
-- common choice when complete files must be accepted or rejected as a unit.
COPY INTO ORDER_LOAD_ERROR_DEMO (
  ORDER_ID, CUSTOMER_ID, ORDER_DATE, STATUS, SALES_CHANNEL,
  CURRENCY, ORDER_TOTAL, DISCOUNT_AMOUNT, SHIPPING_CITY, SHIPPING_COUNTRY
)
FROM @BRONZE_CSV_STAGE
FILES = ('malformed_orders.csv')
FORCE = TRUE
ON_ERROR = 'SKIP_FILE';

SELECT COUNT(*) AS rows_loaded_with_skip_file FROM ORDER_LOAD_ERROR_DEMO;

-- ABORT_STATEMENT is the default and is appropriate when no partial load is
-- acceptable. It intentionally raises an error and stops a worksheet/script,
-- so run it separately when you want to observe that behaviour.
--
-- COPY INTO ORDER_LOAD_ERROR_DEMO
-- FROM @BRONZE_CSV_STAGE
-- FILES = ('malformed_orders.csv')
-- ON_ERROR = 'ABORT_STATEMENT';
