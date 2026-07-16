# Data-loading sample files

| File | Records | Intended exercise |
| --- | ---: | --- |
| `customers.csv` | 30 | Standard headered CSV load into `BRONZE_CUSTOMERS` |
| `orders.csv` | 40 | Standard headered CSV load into `BRONZE_ORDERS` |
| `product_catalog_source.csv` | 20 | Convert to Parquet, then load into `BRONZE_PRODUCT_CATALOG` |
| `events.json` | 18 | JSON array load into `BRONZE_WEB_EVENTS` |
| `device_readings.jsonl` | 12 | Newline-delimited JSON load into `BRONZE_DEVICE_READINGS` |
| `malformed_orders.csv` | 6 | Validation and rejected-record handling; do not use for a normal load |

The datasets use realistic types and edge cases: multiple currencies and countries, optional nested JSON objects, nested arrays, quoted fields, boolean values, and a JSON string column (`attributes`) that can be parsed into `VARIANT` during a transformation load.

`product_catalog_source.csv` is intentionally the Parquet source rather than a prebuilt binary file. Convert it with the tooling used in your environment, preserving the column names and types, and then upload the resulting `.parquet` file to `@BRONZE_PARQUET_STAGE`.

All loading targets belong to `LOAD_TRANSFORM_SERVE.BRONZE`. The transformations and serving sections will use the same source files to create `LOAD_TRANSFORM_SERVE.SILVER` for cleaned and conformed data, followed by business-facing `LOAD_TRANSFORM_SERVE.GOLD` tables or views.
