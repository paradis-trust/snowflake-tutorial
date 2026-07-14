-- Chapter 2: DDL and DML workshop
-- DDL defines and changes database objects.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA DML_DDL;

-- 1. CREATE: add a table for supplier reference data.
CREATE TABLE IF NOT EXISTS SUPPLIERS (
  SUPPLIER_ID NUMBER(10, 0),
  SUPPLIER_NAME VARCHAR,
  COUNTRY VARCHAR,
  IS_PREFERRED BOOLEAN DEFAULT FALSE
);

-- 2. ALTER: add a column without recreating the PRODUCTS table.
ALTER TABLE PRODUCTS
  ADD COLUMN IF NOT EXISTS REORDER_POINT NUMBER(10, 0) DEFAULT 10;

-- 3. ALTER: add an explanatory comment to an object.
ALTER TABLE PRODUCTS
  SET COMMENT = 'Workshop product catalog loaded from products.csv';

-- 4. CREATE: save a reusable query as a view.
CREATE OR REPLACE VIEW ACTIVE_PRODUCTS AS
SELECT
  PRODUCT_ID,
  PRODUCT_NAME,
  CATEGORY,
  UNIT_PRICE,
  REORDER_POINT
FROM PRODUCTS
WHERE IS_ACTIVE = TRUE;

SELECT *
FROM ACTIVE_PRODUCTS
ORDER BY PRODUCT_ID;

-- 5. DESCRIBE and SHOW return object metadata.
DESCRIBE TABLE PRODUCTS;
SHOW TABLES IN SCHEMA DML_DDL;

-- 6. DROP: create and remove a scratch object safely.
CREATE OR REPLACE TRANSIENT TABLE DDL_SCRATCH (
  EXAMPLE_VALUE VARCHAR
);

DROP TABLE DDL_SCRATCH;

-- DDL statements implicitly commit. They cannot be rolled back with ROLLBACK.
