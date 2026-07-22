# Performance workshop

This chapter teaches a measurement-first optimization workflow: reproduce a
problem, inspect its Query Profile, reduce unnecessary work, isolate warehouse
and cache effects, and evaluate whether a paid optimization feature is justified.

Complete Chapters 5 and 6 first. This workshop reuses their role hierarchy and
governed cost tags. It queries the read-only `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100`
schema, whose tables contain several hundred million rows, and creates one
smaller local table from `TPCH_SF10` for the Search Optimization assessment.
Newer accounts normally include the sample database. If yours does not, file 01
contains the one-time shared-database creation statement as a commented option.

## Run order

1. `01_setup_environment.sql` creates `PERFORMANCE_ENGINEER`, `PERFORMANCE_LAB`, an X-Small test warehouse, and a query-ID log.
2. `02_baseline_and_query_profile.sql` runs a deliberately non-prunable predicate and records its query ID.
3. `03_improve_pruning.sql` expresses the same filter as a direct date range and compares scan work.
4. `04_warehouse_sizing_and_caching.sql` compares X-Small and Small cold/warm runs, then demonstrates persisted-result reuse separately.
5. `05_search_optimization_decision.sql` evaluates a selective point lookup, estimates Search Optimization costs, and provides an optional activation experiment.
6. `06_compare_results.sql` joins the captured IDs to immediate Query History and estimates relative execution credits.

Run files 02–06 from the same worksheet if practical. The persistent run log
means separate worksheets also work, provided you complete the chapter within
the seven-day Information Schema Query History retention window.

## Why TPCH_SF100

The existing Bronze, Silver, and Gold workshop tables are intentionally small
and are excellent for functional learning, but too small for stable performance
observations. `TPCH_SF100.LINEITEM` is large enough to make scan and aggregation
costs visible without jumping to Snowflake's multi-terabyte TPC-DS samples.

Exact timings are not expected to match between accounts. Cloud, region,
warehouse provisioning, concurrent workload, cache state, and platform changes
all affect duration. Compare physical work—especially partitions and bytes
scanned—before comparing elapsed time.

## Query Profile exercise

After each captured benchmark:

1. Open **Activity → Query History** in Snowsight.
2. Search for the query ID printed by the SQL file and open it.
3. In Query Profile, identify the operator consuming the largest share of time.
4. Select the TableScan node and record partitions scanned/total, bytes scanned, rows produced, and percentage scanned from cache.
5. Inspect Filter and Aggregate nodes and note any local or remote spilling.
6. For warehouse comparisons, compare `XS_COLD` with `SMALL_COLD`, then `XS_WARM` with `SMALL_WARM`.
7. For persisted-result reuse, compare `RESULT_CACHE_POPULATE` and `RESULT_CACHE_REUSE`. A reused result does not perform the original physical scan.

The expected baseline bottleneck is the large TableScan followed by aggregation.
The optimized date range should expose more effective micro-partition pruning.
If it does not materially reduce scanned partitions in your run, that is still a
valid result: inspect the table's existing organization and do not claim an
optimization from elapsed-time noise.

## Interpreting warehouse size and cache

Resizing is not a substitute for reducing unnecessary work. A larger warehouse
can shorten a CPU- or scan-heavy query, but it consumes credits at a higher rate.
The comparison query reports a standard Generation 1 size × execution-time
estimate to discuss this trade-off; actual billing also depends on resource
constraint, warehouse idle time, and minimum charges when compute is provisioned.

Two caches are demonstrated deliberately:

- The warehouse data cache can reduce remote reads while a warehouse remains running. Persisted-result reuse is disabled for those runs.
- The persisted query-result cache can bypass execution for an identical query when its reuse conditions are satisfied.

Do not benchmark a physical optimization with persisted-result reuse enabled.
Use multiple passes in a real assessment and compare consistent cache states.

## Search Optimization decision

The Snowflake free trial includes Enterprise Edition, so the workshop executes
the Search Optimization cost estimator directly. Search Optimization uses
serverless build and maintenance compute plus storage. It is designed for highly
selective access patterns such as repeated equality lookups, not as a generic
way to make every query faster.

The workshop therefore stops at a decision by default. A single lookup on a
short-lived lab table cannot repay the service's build and storage cost. In a
production assessment, use representative Query History to establish frequency
and latency, inspect the baseline scan selectivity, estimate cost, enable only
`EQUALITY(O_ORDERKEY)` in a test environment, wait until its build is complete,
and confirm a `Search Optimization Access` node in Query Profile. Keep it only
if measured workload benefit exceeds its ongoing cost.

## Practice outcomes

After completing the chapter, you will have:

- run and profiled a deliberately inefficient query;
- identified scan and aggregation work in Query Profile;
- improved a predicate to expose micro-partition pruning;
- compared warehouse sizes under equivalent cache conditions;
- distinguished warehouse data cache from persisted-result reuse;
- compared duration, bytes scanned, and approximate compute trade-offs; and
- made an evidence-based Search Optimization decision.

## Snowflake references

- [TPC-H sample data](https://docs.snowflake.com/en/user-guide/sample-data-tpch)
- [Query Profile](https://docs.snowflake.com/en/user-guide/ui-query-profile)
- [Persisted query results](https://docs.snowflake.com/en/user-guide/querying-persisted-results)
- [Warehouse considerations and cache](https://docs.snowflake.com/en/user-guide/warehouses-considerations)
- [Clustering and pruning](https://docs.snowflake.com/en/user-guide/tables-clustering-keys)
- [Search Optimization point lookups](https://docs.snowflake.com/en/user-guide/search-optimization/point-lookup-queries)
- [Search Optimization cost estimates](https://docs.snowflake.com/en/sql-reference/functions/system_estimate_search_optimization_costs)
