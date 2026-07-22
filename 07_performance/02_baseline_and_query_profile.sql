-- Establish the deliberately inefficient baseline on TPCH_SF100.LINEITEM.
-- TO_CHAR is applied to every L_SHIPDATE value before filtering, obscuring the
-- direct range predicate that micro-partition metadata can prune efficiently.

USE ROLE PERFORMANCE_ENGINEER;
USE DATABASE PERFORMANCE_LAB;
USE SCHEMA BENCHMARKS;
USE WAREHOUSE PERF_TEST_WH;

ALTER WAREHOUSE PERF_TEST_WH SUSPEND;
ALTER WAREHOUSE PERF_TEST_WH SET WAREHOUSE_SIZE = 'XSMALL';
ALTER WAREHOUSE PERF_TEST_WH RESUME;

-- Disable persisted-result reuse while comparing physical execution. This does
-- not disable the running warehouse's local data cache.
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

SELECT /* CH07_BASELINE_NON_PRUNABLE */
  SUM(L_EXTENDEDPRICE * L_DISCOUNT) AS REVENUE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM
WHERE TO_CHAR(L_SHIPDATE, 'YYYY') = '1994'
  AND L_DISCOUNT BETWEEN 0.05 AND 0.07
  AND L_QUANTITY < 24;

INSERT INTO BENCHMARKS.RUN_LOG (EXPERIMENT, RUN_LABEL, QUERY_ID, NOTES)
SELECT
  'PRUNING',
  'NON_PRUNABLE_PREDICATE',
  LAST_QUERY_ID(),
  'X-Small, cold warehouse, persisted result cache disabled';

-- Open the captured query in Snowsight Query History. In Query Profile inspect:
--   * TableScan percentage of total duration;
--   * partitions scanned versus partitions total;
--   * bytes scanned and rows produced by the scan;
--   * the Filter and Aggregate operators; and
--   * local or remote spilling, if present.
SELECT *
FROM BENCHMARKS.RUN_LOG
WHERE RUN_LABEL = 'NON_PRUNABLE_PREDICATE';
