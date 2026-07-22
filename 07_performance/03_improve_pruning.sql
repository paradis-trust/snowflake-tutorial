-- Express the same 1994 condition as a half-open range on the stored column.
-- This is semantically equivalent for a DATE and exposes partition min/max
-- metadata directly to Snowflake's pruning engine.

USE ROLE PERFORMANCE_ENGINEER;
USE DATABASE PERFORMANCE_LAB;
USE SCHEMA BENCHMARKS;
USE WAREHOUSE PERF_TEST_WH;

ALTER WAREHOUSE PERF_TEST_WH SUSPEND;
ALTER WAREHOUSE PERF_TEST_WH SET WAREHOUSE_SIZE = 'XSMALL';
ALTER WAREHOUSE PERF_TEST_WH RESUME;
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

SELECT /* CH07_PRUNABLE_RANGE */
  SUM(L_EXTENDEDPRICE * L_DISCOUNT) AS REVENUE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM
WHERE L_SHIPDATE >= DATE '1994-01-01'
  AND L_SHIPDATE < DATE '1995-01-01'
  AND L_DISCOUNT BETWEEN 0.05 AND 0.07
  AND L_QUANTITY < 24;

INSERT INTO BENCHMARKS.RUN_LOG (EXPERIMENT, RUN_LABEL, QUERY_ID, NOTES)
SELECT
  'PRUNING',
  'PRUNABLE_RANGE_PREDICATE',
  LAST_QUERY_ID(),
  'Equivalent range predicate; compare scan statistics with the baseline';

-- Confirm that both formulations returned the same revenue, then compare their
-- TableScan nodes in Query Profile. Effective pruning should reduce partitions
-- and bytes scanned; elapsed time is secondary because runtime conditions vary.
SELECT *
FROM BENCHMARKS.RUN_LOG
WHERE EXPERIMENT = 'PRUNING'
ORDER BY CAPTURED_AT;
