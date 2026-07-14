# SQL in Snowflake

This chapter uses the writable TPC-H data created by [01_copy_tpch_sample_data.sql](01_copy_tpch_sample_data.sql). Run that script first, then run the examples in [02_basic_analytics_queries.sql](02_basic_analytics_queries.sql).

The focus is analytical SQL: reading, shaping, combining, and summarising data to answer business questions. It deliberately does not cover relational design, constraints, or transaction processing.

## Dataset at a glance

The `SQL_IN_SNOWFLAKE.TPCH` schema is a small supply-chain and sales model. `ORDERS` is an order header, `LINEITEM` contains its individual items, and `CUSTOMER`, `PART`, `SUPPLIER`, `NATION`, and `REGION` add descriptive context. `PARTSUPP` relates parts to their suppliers.

## Core operations

| Operation | Purpose |
| --- | --- |
| `SELECT`, column list, aliases | Return only the fields needed and give calculated fields clear names. |
| `LIMIT` | Inspect a small sample while exploring a table. |
| `WHERE` | Filter rows before analysis using comparisons, `AND`/`OR`, `IN`, `BETWEEN`, and pattern matching with `LIKE`. |
| `ORDER BY` | Sort a result for reading or ranking. |
| `DISTINCT` | Return unique values, such as the available market segments. |
| Expressions | Calculate values from columns, for example net revenue after discount. |
| `CASE` and `COALESCE` | Derive categories and handle missing values. |
| Aggregate functions | Summarise a set of rows with `COUNT`, `SUM`, `AVG`, `MIN`, and `MAX`. |
| `GROUP BY` | Produce one aggregate result per business dimension, such as month, customer, or country. |
| `HAVING` | Filter aggregated groups after `GROUP BY`. |
| Date functions | Group dates with `DATE_TRUNC`, compare them with `DATEDIFF`, and filter a date range. |
| `JOIN` | Combine facts with dimensions: for example, orders with customers and customers with geography. Use `LEFT JOIN` when unmatched fact rows should remain visible. |
| CTE (`WITH`) | Give a multi-step analysis a readable, temporary named result. |
| Subquery | Use the result of one query as an input or filter for another. |
| `UNION ALL` | Stack compatible result sets. Prefer it over `UNION` unless removing duplicate rows is intended. |
| Window functions | Calculate across related rows while retaining each row: running totals, rankings, and comparisons with prior rows. |
| `QUALIFY` | Snowflake-specific filtering of window-function results, without wrapping the query in another subquery. |
| Views | Save a reusable query as a named, virtual analytical dataset. |

## A helpful query order

For a typical analytical query, think in this order: `FROM` and `JOIN` choose the data, `WHERE` removes unwanted rows, `GROUP BY` creates groups, aggregates calculate metrics, `HAVING` removes unwanted groups, window functions add row-aware metrics, `QUALIFY` filters those metrics, then `SELECT`, `ORDER BY`, and `LIMIT` shape the final result.

The examples are intentionally read-only, except for the final `CREATE OR REPLACE VIEW` statement. They may be run independently after selecting the chapter database and schema.
