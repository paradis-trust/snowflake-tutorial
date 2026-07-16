# Transformation and Serving

This workshop builds on the bronze tables loaded in `../03_data_loading/` and
uses the same `LOAD_TRANSFORM_SERVE` database throughout the medallion flow.

Run the files in order:

1. `01_setup_silver_gold.sql` creates the `SILVER` and `GOLD` schemas.
2. `02_full_refresh_transformation_patterns.sql` demonstrates CTAS, `INSERT INTO … SELECT`, `TRUNCATE` + `INSERT`, and `CREATE OR REPLACE TABLE AS SELECT` while creating typed silver tables.
3. `03_incremental_processing_and_orchestration.sql` introduces an append-only stream, `MERGE`, a task definition, and a dynamic gold daily-sales table. It uses `COMPUTE_WH`; replace that warehouse name if needed. The task remains suspended until you explicitly resume it.
4. `04_serving_views.sql` creates a standard view, an Enterprise Edition materialized view, and a secure aggregate view.

The full-refresh script deliberately shows several patterns against small
workshop data. In a real pipeline, select one pattern per table based on its
contract: use `TRUNCATE` + `INSERT` when preserving the table object matters,
`CREATE OR REPLACE` when replacing it is acceptable, and `MERGE` for upserts.

The stream starts tracking only changes made after it is created. Load or insert
another bronze order after running script 3 to observe the stream and task
workflow. Dynamic tables are an alternative declarative approach: their target
lag is a freshness goal, not a strict refresh interval.
