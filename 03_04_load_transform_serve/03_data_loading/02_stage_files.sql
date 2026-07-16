-- Module 3: Data Loading
-- Upload local workshop files to the internal named stages.
--
-- PUT is a client-side command. Run this file with SnowSQL, not from a
-- Snowsight worksheet. Replace <repo-root> once below with this repository's
-- absolute path. Snowflake SQL SET variables cannot be used in PUT file URIs,
-- so this uses SnowSQL client-side variable substitution instead.

!set variable_substitution=true
!define repo_root=<repo-root>

USE DATABASE LOAD_TRANSFORM_SERVE;
USE SCHEMA BRONZE;

PUT file://&{repo_root}/03_load_transform_serve/data/customers.csv
  @BRONZE_CSV_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

PUT file://&{repo_root}/03_load_transform_serve/data/orders.csv
  @BRONZE_CSV_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

-- Keep the malformed file in the same stage. Later scripts select an explicit
-- filename, so it cannot be picked up accidentally by a normal load.
PUT file://&{repo_root}/03_load_transform_serve/data/malformed_orders.csv
  @BRONZE_CSV_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

PUT file://&{repo_root}/03_load_transform_serve/data/events.json
  @BRONZE_JSON_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

PUT file://&{repo_root}/03_load_transform_serve/data/device_readings.jsonl
  @BRONZE_JSON_LINES_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

-- Generate this file first with data/convert_csv_to_parquet.py.
PUT file://&{repo_root}/03_load_transform_serve/data/product_catalog_source.parquet
  @BRONZE_PARQUET_STAGE
  AUTO_COMPRESS = FALSE
  OVERWRITE = TRUE;

LIST @BRONZE_CSV_STAGE;
LIST @BRONZE_JSON_STAGE;
LIST @BRONZE_JSON_LINES_STAGE;
LIST @BRONZE_PARQUET_STAGE;
