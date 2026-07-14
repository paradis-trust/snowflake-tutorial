# Semi-structured data workshop

This workshop loads JSON files into Snowflake `VARIANT` columns, then queries and flattens their nested values.

Run the files in order:

1. `01_setup_environment.sql` creates the `SQL_IN_SNOWFLAKE.SEMI_STRUCTURED` schema, JSON file format, internal stage, and raw `VARIANT` tables.
2. `02_stage_and_load_json.sql` uploads the JSON files and loads them. `PUT` is a client command, so run the upload statements with SnowSQL, Snowflake CLI, or another supported client; they do not run in a Snowsight worksheet.
3. `03_query_variant.sql` demonstrates path traversal, casts, filters, `GET_PATH`, and JSON nulls.
4. `04_flatten_json.sql` expands arrays and objects into rows, explores unknown structures, and creates a relational order-item table.

The JSON files intentionally contain nested objects, arrays, empty arrays, optional values, and the `shipping-method` key. JSON keys are case-sensitive when addressed by a path; keys that contain a hyphen must be double-quoted, for example `SRC:"shipping-method"`.
