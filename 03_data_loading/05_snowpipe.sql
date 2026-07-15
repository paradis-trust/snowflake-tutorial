-- Module 3: Data Loading
-- Load the JSON Lines device readings through Snowpipe.
--
-- This workshop uses manual Snowpipe (AUTO_INGEST = FALSE) with the internal
-- named stage already created in 01_setup_environment.sql. It is runnable
-- without a cloud-storage notification integration. In production, configure
-- an external S3, Azure Blob, or GCS stage and AUTO_INGEST = TRUE.

USE DATABASE DATA_LOADING;
USE SCHEMA BRONZE;

CREATE OR REPLACE PIPE BRONZE_DEVICE_READINGS_PIPE
  AUTO_INGEST = FALSE
  COMMENT = 'Manual Snowpipe workshop: JSON Lines device readings'
AS
COPY INTO BRONZE_DEVICE_READINGS (READING, SOURCE_FILE)
FROM (
  SELECT $1, METADATA$FILENAME
  FROM @BRONZE_JSON_LINES_STAGE
);

DESCRIBE PIPE BRONZE_DEVICE_READINGS_PIPE;

-- Queue files staged in the last seven days. REFRESH is useful for this small
-- workshop; production manual Snowpipe normally calls the REST API instead.
ALTER PIPE BRONZE_DEVICE_READINGS_PIPE REFRESH;

SELECT SYSTEM$PIPE_STATUS('DATA_LOADING.BRONZE.BRONZE_DEVICE_READINGS_PIPE');

-- Snowpipe loads asynchronously. Re-run these queries after pendingFileCount
-- reaches 0 in SYSTEM$PIPE_STATUS.
SELECT COUNT(*) AS device_reading_count FROM BRONZE_DEVICE_READINGS;
SELECT * FROM BRONZE_DEVICE_READINGS ORDER BY LOADED_AT DESC;
