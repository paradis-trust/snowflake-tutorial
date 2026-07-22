# Management workshop

This chapter covers day-to-day warehouse operations, monitoring and
troubleshooting, cost attribution and controls, recovery, and environment
management. Complete Chapters 3–5 first because the exercises reuse
`LOAD_TRANSFORM_SERVE` and its role hierarchy.

Run the SQL files in order:

1. `01_setup_and_warehouse_administration.sql` creates `MANAGEMENT_ADMIN`, an isolated lab database, and X-Small, Small, and Medium warehouses. It also creates governed `COST_CENTER`, `WORKLOAD_TYPE`, and `ENVIRONMENT` tags and classifies the workshop user, databases, and warehouses once.
2. `02_monitoring_and_troubleshooting.sql` generates human ad-hoc queries without manual query tags, contrasts immediate Information Schema history with delayed `ACCOUNT_USAGE`, and investigates latency, queuing, spilling, and failures.
3. `03_cost_analysis_and_attribution.sql` attributes warehouse runtime through warehouse tags and human query costs through user tags, then compares theoretical warehouse costs.
4. `04_cost_controls_resource_monitor_and_budget.sql` creates an enforcing resource monitor, guides you through creating a tag-scoped custom budget in Snowsight, and inspects that budget with SQL.
5. `05_time_travel_and_recovery.sql` recovers accidental DML with historical cloning, then drops and undrops an isolated table.
6. `06_clone_dev_environment.sql` creates a writable zero-copy DEV database and reviews cloned automation and access behavior.
7. `07_optional_cleanup.sql` contains commented cleanup statements.

## Operational model

`MANAGEMENT_ADMIN` is a custom role beneath `SYSADMIN`. It receives operational
metadata and budget privileges without using `ACCOUNTADMIN` for normal work.
`ACCOUNTADMIN` remains necessary for creating the resource monitor and for the
initial Snowflake database-role grants. Its read-only Snowflake database roles
cover usage, governance, object, and security metadata needed by the exercises.
`GOVERNANCE_ADMIN` owns and centrally applies the management taxonomy in
`MANAGEMENT_LAB.GOVERNANCE`, consistent with the governance separation from
Chapter 5. Keeping these account-wide tags outside `LOAD_TRANSFORM_SERVE`
prevents an environment clone from duplicating the authoritative taxonomy.

The examples use `MGMT_XS_WH` for runnable exercises. `MGMT_SMALL_WH` and
`MGMT_MEDIUM_WH` remain suspended unless you explicitly test them. Resuming any
warehouse starts billing with a 60-second minimum, followed by per-second
billing. The dollar estimate uses an illustrative credit price; replace it with
your contracted price or report credits only.

`ACCOUNT_USAGE` views are not real-time. Depending on the view, the queries in
this workshop can take minutes or hours to appear. Use Information Schema or
Snowsight Query History for an active incident, then use `ACCOUNT_USAGE` for
durable reporting and trends.

### Production attribution model

Human ad-hoc users do not set query tags in this workshop. Snowflake records
their user, active role, and warehouse automatically. Governed object tags add
the organizational dimensions that Snowflake cannot infer:

- `COST_CENTER=DATA_PLATFORM` is assigned to the workshop user and warehouses;
- `WORKLOAD_TYPE` distinguishes `ADHOC`, `ELT`, and `BI` compute;
- `ENVIRONMENT=TRAINING` is independent of cost ownership and workload type;
  the DEV clone is explicitly reclassified as `ENVIRONMENT=DEV`.

Production identity provisioning should apply user tags automatically from the
identity provider, commonly through SCIM. Infrastructure-as-code should apply
warehouse tags when resources are provisioned. This gives ad-hoc users a
zero-touch workflow and keeps values constrained by each tag's `ALLOWED_VALUES`.

`QUERY_TAG` remains useful for dynamic context that is available only to an
application or orchestrator, such as an Airflow DAG run, dbt model, notebook
execution, or application request ID. Those systems should inject it when they
open the connection; it should not duplicate user, role, warehouse, or governed
object-tag metadata. Because users can change a query tag, never treat it as an
authorization or policy-enforcement attribute.

## Recommended Snowsight exercises

### Warehouse operations

1. Open **Admin → Warehouses** (the navigation label can vary slightly by UI release).
2. Compare `MGMT_XS_WH`, `MGMT_SMALL_WH`, and `MGMT_MEDIUM_WH`.
3. Confirm their size, suspended state, auto-suspend, and auto-resume settings.
4. Resume and suspend only `MGMT_XS_WH`; observe the state transition.

SQL remains preferable for repeatable provisioning, peer review, and change
management. Snowsight is useful for quick state inspection and emergency
operations.

### Query troubleshooting

1. Open **Activity → Query History**.
2. Filter by warehouse `MGMT_XS_WH`, role `DATA_ANALYST`, and your user name.
3. Open the aggregation query and inspect Query Profile.
4. Review the most expensive operators, partitions scanned, bytes scanned,
   spilling, and time spent queuing versus executing.
5. Use the query ID to correlate the profile with the SQL history queries.

### Cost management and budgets

1. Open **Admin → Cost management → Consumption** and compare the chart with `WAREHOUSE_METERING_HISTORY`.
2. Open **Admin → Cost management → Resource monitors** and inspect `MANAGEMENT_LAB_MONITOR`.
3. Follow the instructions in file 04 to create `MANAGEMENT_DATA_PLATFORM_BUDGET` from **Admin → Cost management → Budgets**.
4. Configure a verified notification email in Snowsight if desired.
5. Return to file 04 and run the read-only SQL calls to inspect the budget configuration and scope.

Resource monitors and budgets are complementary:

- A resource monitor can suspend its assigned user-managed warehouses, but it does not cover serverless services.
- A budget monitors and forecasts a broader resource scope, including supported serverless costs, but a basic budget is not a hard spending cap.

Tag discovery and budget usage are asynchronous. A newly attached tag can take
up to two hours to appear for budget selection, and budget scope/usage refreshes
can take longer unless low-latency budget options are enabled.

If the account or region does not support Snowflake Budgets, skip the custom
budget section of file 04 and complete the resource-monitor exercise. The two
features are independent.

## Recovery and DEV safeguards

Time Travel availability is bounded by each object’s retention period. The lab
uses one day and should be completed without delay. `UNDROP` fails if another
table already occupies the same name.

The DEV clone is writable and independent after creation, but it initially
shares unchanged micro-partitions with the source. New DEV changes consume
additional storage. Cloned tasks and dynamic tables are suspended. The internal
Snowpipe pipe and internal stage files are not cloned by default, preventing an
accidental duplicate ingestion path. Audit cloned privileges before granting
DEV access, and use environment-specific warehouses, integrations, tags, and
schedules before enabling automation.

## Practice outcomes

After completing the chapter, you will have:

- provisioned warehouses of multiple sizes with automatic lifecycle controls;
- investigated query and warehouse history;
- queried operational and billing views in `ACCOUNT_USAGE`;
- attributed warehouse and human query costs with governed object tags;
- configured a resource monitor and a tag-scoped custom budget;
- recovered DML and a dropped table with Time Travel; and
- created and reviewed a zero-copy DEV database clone.

## Snowflake references

- [Warehouse sizing and billing](https://docs.snowflake.com/en/user-guide/warehouses-overview)
- [Query History](https://docs.snowflake.com/en/sql-reference/account-usage/query_history)
- [Query cost attribution](https://docs.snowflake.com/en/sql-reference/account-usage/query_attribution_history)
- [Cost attribution with warehouse and user tags](https://docs.snowflake.com/en/user-guide/cost-attributing)
- [Object tagging](https://docs.snowflake.com/en/user-guide/object-tagging)
- [Resource monitors](https://docs.snowflake.com/en/sql-reference/sql/create-resource-monitor)
- [Custom budgets](https://docs.snowflake.com/en/user-guide/budgets/custom-budget)
- [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel)
- [Cloning considerations](https://docs.snowflake.com/en/user-guide/object-clone)
