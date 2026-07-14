-- Chapter 2: DDL and DML workshop
-- Upload the repository CSV files to the internal stage, then load them.
--
-- PUT is a client-side command. Run it with SnowSQL, Snowflake CLI, or another
-- supported client. Replace <repo-root> with the repository's absolute path.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA DML_DDL;

PUT file://<repo-root>/02_sql_in_snowflake/10_dml_ddl_operations/products.csv
  @DML_DDL_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

PUT file://<repo-root>/02_sql_in_snowflake/10_dml_ddl_operations/inventory_adjustments.csv
  @DML_DDL_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

LIST @DML_DDL_STAGE;

COPY INTO PRODUCTS (
  PRODUCT_ID,
  PRODUCT_NAME,
  CATEGORY,
  UNIT_PRICE,
  IS_ACTIVE
)
FROM @DML_DDL_STAGE
FILES = ('products.csv')
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO INVENTORY_ADJUSTMENTS (
  ADJUSTMENT_ID,
  PRODUCT_ID,
  QUANTITY_CHANGE,
  REASON,
  ADJUSTED_ON
)
FROM @DML_DDL_STAGE
FILES = ('inventory_adjustments.csv')
ON_ERROR = 'ABORT_STATEMENT';

SELECT 'PRODUCTS' AS table_name, COUNT(*) AS row_count FROM PRODUCTS
UNION ALL
SELECT 'INVENTORY_ADJUSTMENTS', COUNT(*) FROM INVENTORY_ADJUSTMENTS
ORDER BY table_name;

-- COPY tracks loaded files. To intentionally reload a file, TRUNCATE the
-- target table first and add FORCE = TRUE to its COPY INTO statement.
