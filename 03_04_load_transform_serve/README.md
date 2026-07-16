# Load, Transform, and Serve

This shared area uses one dataset and one Snowflake database throughout the
data lifecycle: ingestion into bronze, transformation into silver, and serving
through gold tables or views.

The current material is organized by lifecycle step:

- `03_data_loading/` ingests source files into bronze.
- `04_transformation_and_serving/` transforms bronze data and serves gold results.

The source files are in `data/` so every section can reuse them without copying
files.

Database structure:

- `LOAD_TRANSFORM_SERVE.BRONZE` — source-aligned loaded data.
- `LOAD_TRANSFORM_SERVE.SILVER` — cleaned and conformed data, introduced in the transformations section.
- `LOAD_TRANSFORM_SERVE.GOLD` — business-facing tables or views, introduced in the serving section.
