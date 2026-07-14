# DDL and DML workshop

This workshop uses a small product catalog to practise basic object definition and data manipulation in an isolated schema: `SQL_IN_SNOWFLAKE.DML_DDL`.

Run the files in order:

1. `01_setup_environment.sql` creates the schema, CSV file format, internal stage, and base tables.
2. `02_stage_and_load_csv.sql` uploads the CSV files and loads them. The `PUT` commands require SnowSQL, Snowflake CLI, or another supported client; they do not run in a Snowsight worksheet.
3. `03_ddl_operations.sql` demonstrates `CREATE`, `ALTER`, `DESCRIBE`, `SHOW`, a view, and a safe scratch-table `DROP`.
4. `04_dml_operations.sql` demonstrates `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, and an explicit `BEGIN TRANSACTION` / `ROLLBACK`.

DDL defines or changes database objects. DML changes table rows. In Snowflake, DDL statements implicitly commit an active transaction, so only place DML and queries inside the explicit transaction example.
