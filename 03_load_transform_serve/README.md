# Load, Transform, and Serve

This shared area uses one dataset and one Snowflake database throughout the
data lifecycle: ingestion into bronze, transformation into silver, and serving
through gold tables or views.

The current material is in `03_data_loading/`. The source files are in `data/`
so later transformation and serving sections can reuse them without copying
files.

Database structure:

- `LOAD_TRANSFORM_SERVE.BRONZE` — source-aligned loaded data.
- `LOAD_TRANSFORM_SERVE.SILVER` — cleaned and conformed data, introduced in the transformations section.
- `LOAD_TRANSFORM_SERVE.GOLD` — business-facing tables or views, introduced in the serving section.
