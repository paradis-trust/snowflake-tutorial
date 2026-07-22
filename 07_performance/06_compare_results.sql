-- Compare immediate history for the query IDs captured by the workshop.
-- Timings vary with region, warehouse availability, cache state, and service
-- load. Prefer repeated runs and compare like-for-like cache states.

USE ROLE PERFORMANCE_ENGINEER;
USE DATABASE PERFORMANCE_LAB;
USE SCHEMA BENCHMARKS;
USE WAREHOUSE PERF_TEST_WH;

WITH RECENT_QUERY_HISTORY AS (
  SELECT
    QUERY_ID,
    WAREHOUSE_SIZE,
    TOTAL_ELAPSED_TIME,
    COMPILATION_TIME,
    EXECUTION_TIME,
    BYTES_SCANNED
  FROM TABLE(
    PERFORMANCE_LAB.INFORMATION_SCHEMA.QUERY_HISTORY(
      END_TIME_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP()),
      RESULT_LIMIT => 10000
    )
  )
)
SELECT
  L.EXPERIMENT,
  L.RUN_LABEL,
  H.WAREHOUSE_SIZE,
  ROUND(H.TOTAL_ELAPSED_TIME / 1000, 3) AS ELAPSED_SECONDS,
  ROUND(H.COMPILATION_TIME / 1000, 3) AS COMPILATION_SECONDS,
  ROUND(H.EXECUTION_TIME / 1000, 3) AS EXECUTION_SECONDS,
  H.BYTES_SCANNED,
  ROUND(
    H.EXECUTION_TIME / 3600000
    * CASE UPPER(REPLACE(H.WAREHOUSE_SIZE, '-', ''))
        WHEN 'XSMALL' THEN 1
        WHEN 'SMALL' THEN 2
        WHEN 'MEDIUM' THEN 4
        WHEN 'LARGE' THEN 8
      END,
    6
  ) AS APPROX_EXECUTION_CREDITS,
  L.NOTES
FROM BENCHMARKS.RUN_LOG L
LEFT JOIN RECENT_QUERY_HISTORY H
  ON H.QUERY_ID = L.QUERY_ID
ORDER BY L.CAPTURED_AT;

-- APPROX_EXECUTION_CREDITS assumes standard Generation 1 size rates and compares
-- size x execution time only. It is not an invoice: actual billing depends on
-- resource constraint, idle time, per-second billing, and start/resize minimums.
