# Data Loading

This module loads source data into the `LOAD_TRANSFORM_SERVE.BRONZE` layer. Bronze data
remains source-aligned and auditable: the only load-time changes are type
mapping and source-file metadata. Data cleaning, deduplication, conformance,
and business metrics belong to the following transformations module.

Run the files in order:

1. `01_setup_environment.sql` creates the bronze schema, file formats, named internal stages, and target tables.
2. Run `03_04_load_transform_serve/data/convert_csv_to_parquet.py` from its `data` directory to generate `product_catalog_source.parquet`. The generated Parquet file is already included when available.
3. `02_stage_files.sql` uploads the workshop files. Its `PUT` commands require SnowSQL, the Snowflake CLI, or another supported client; they do not run in a Snowsight worksheet.
4. `03_bulk_load_copy_into.sql` loads CSV, Parquet, and JSON files with `COPY INTO`. `device_readings.jsonl` is intentionally held back for Snowpipe.
5. `04_validation_and_error_handling.sql` checks the malformed CSV, writes rejected records to the rejected-files stage, and compares `CONTINUE` with `SKIP_FILE`. Its `ABORT_STATEMENT` example is commented out because it intentionally stops execution.
6. `05_snowpipe.sql` creates a manual Snowpipe for the JSON Lines device readings and queues the staged file with `ALTER PIPE ... REFRESH`.
7. `06_monitor_load_history.sql` queries `COPY_HISTORY` for both `COPY INTO` and Snowpipe metadata.

The Snowpipe example uses an internal stage with `AUTO_INGEST = FALSE` so it
works without cloud credentials or notification integrations. It is still
Snowpipe and loads asynchronously. For a production auto-ingest setup, use an
external S3, Azure Blob Storage, or GCS stage with the appropriate storage and
notification integrations.
