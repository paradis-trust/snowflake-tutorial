-- Search Optimization is evaluated on a local table because shared sample
-- tables are read-only. The table is organized by order date, representing an
-- analytical load pattern, while the candidate workload is point lookup by ID.

USE ROLE PERFORMANCE_ENGINEER;
USE DATABASE PERFORMANCE_LAB;
USE SCHEMA BENCHMARKS;
USE WAREHOUSE PERF_TEST_WH;

ALTER WAREHOUSE PERF_TEST_WH SUSPEND;
ALTER WAREHOUSE PERF_TEST_WH SET WAREHOUSE_SIZE = 'XSMALL';
ALTER WAREHOUSE PERF_TEST_WH RESUME;
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

CREATE TRANSIENT TABLE ORDER_LOOKUP
  DATA_RETENTION_TIME_IN_DAYS = 0
  COMMENT = 'SF10 orders organized by date for point-lookup evaluation'
AS
SELECT
  O_ORDERKEY,
  O_CUSTKEY,
  O_ORDERSTATUS,
  O_TOTALPRICE,
  O_ORDERDATE,
  O_ORDERPRIORITY,
  O_CLERK
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
ORDER BY O_ORDERDATE;

ALTER WAREHOUSE PERF_TEST_WH SUSPEND;
ALTER WAREHOUSE PERF_TEST_WH RESUME;

SELECT /* CH07_POINT_LOOKUP_BASELINE */
  O_ORDERKEY,
  O_CUSTKEY,
  O_ORDERSTATUS,
  O_TOTALPRICE,
  O_ORDERDATE,
  O_ORDERPRIORITY,
  O_CLERK
FROM BENCHMARKS.ORDER_LOOKUP
WHERE O_ORDERKEY = 1;

INSERT INTO BENCHMARKS.RUN_LOG (EXPERIMENT, RUN_LABEL, QUERY_ID, NOTES)
SELECT
  'SEARCH_OPTIMIZATION',
  'POINT_LOOKUP_WITHOUT_SEARCH_OPTIMIZATION',
  LAST_QUERY_ID(),
  'Highly selective equality lookup on a table organized by another dimension';

SHOW TABLES LIKE 'ORDER_LOOKUP' IN SCHEMA PERFORMANCE_LAB.BENCHMARKS;

SELECT
  "name" AS TABLE_NAME,
  "rows" AS ROW_COUNT,
  "bytes" AS COMPRESSED_BYTES,
  "search_optimization" AS SEARCH_OPTIMIZATION
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Estimate build, storage, and maintenance cost before enabling the service.
-- The free trial includes Enterprise Edition. Estimates are best effort and can
-- differ materially from actual consumption.
SELECT SYSTEM$ESTIMATE_SEARCH_OPTIMIZATION_COSTS(
  'PERFORMANCE_LAB.BENCHMARKS.ORDER_LOOKUP',
  'EQUALITY(O_ORDERKEY)'
) AS SEARCH_OPTIMIZATION_COST_ESTIMATE;

-- Decision checklist:
--   * Did TableScan touch a large share of partitions to return one row?
--   * Is this equality lookup frequent and latency-sensitive in production?
--   * Is the table large enough for the saved compute/latency to matter?
--   * Do estimated build, storage, and DML-maintenance costs fit the SLA budget?
--   * Would a clustering key benefit more common range workloads instead?
--
-- For this short-lived workshop and a single lookup, do not enable Search
-- Optimization: its background build and storage have no recurring workload to
-- repay them. For a large production table with frequent point lookups, test the
-- column-specific configuration below against representative query history.
--
-- Optional experiment after deciding that measured benefit justifies it:
ALTER TABLE BENCHMARKS.ORDER_LOOKUP
  ADD SEARCH OPTIMIZATION ON EQUALITY(O_ORDERKEY);
SHOW TABLES LIKE 'ORDER_LOOKUP' IN SCHEMA PERFORMANCE_LAB.BENCHMARKS;
DESCRIBE SEARCH OPTIMIZATION ON BENCHMARKS.ORDER_LOOKUP;
--
-- Wait for SEARCH_OPTIMIZATION_PROGRESS to reach 100 before rerunning the exact
-- point lookup with USE_CACHED_RESULT = FALSE. Confirm that Query Profile shows
-- a Search Optimization Access node; Snowflake chooses whether to use it.

-- Though note that in our case the table has less than 10 partitions making the
-- Search Optimization feature very less powerful.
