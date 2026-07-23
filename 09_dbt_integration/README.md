# dbt integration on Snowflake

This chapter introduces the Snowflake-native dbt workflow without repeating a
full dbt course. The repository folder is a complete, dependency-free dbt
project that can be imported into a Snowsight workspace and deployed as a
versioned `DBT PROJECT` object.

The project reads the customer and order tables loaded in Chapter 3. It writes
only to the isolated `DBT_ONBOARDING` database and does not replace the Silver
or Gold objects built manually in Chapter 4. Complete Chapters 3–6 first so the
source database, owner role, functional roles, and governed tags exist.

## Project graph

```text
LOAD_TRANSFORM_SERVE.BRONZE.BRONZE_CUSTOMERS
    └── stg_customers [view]
          └── int_customers_deduplicated [view]
                └── dim_customers [table]
                      └── customer_order_summary [table]

LOAD_TRANSFORM_SERVE.BRONZE.BRONZE_ORDERS
    └── stg_orders [view]
          └── int_orders_deduplicated [view]
                └── fct_orders [incremental table / MERGE]
                      ├── customer_order_summary [table]
                      └── daily_sales [table]
```

`customer_order_summary` has customer-and-currency grain. Values in JPY, EUR,
USD, and other currencies are never summed together because the workshop has no
exchange-rate source.

The layers have deliberately different responsibilities:

- staging stays close to the Bronze sources and performs only basic renaming,
  casing, trimming, and null normalization;
- intermediate contains purpose-built transformation logic, including selecting
  the latest delivery of each customer and order; and
- marts contains every business-facing dimension, fact, and aggregate.

## Project structure

```text
09_dbt_integration/
├── dbt_project.yml
├── profiles.yml
├── README.md
├── .gitignore
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   ├── _staging.yml
│   │   ├── stg_customers.sql
│   │   └── stg_orders.sql
│   ├── intermediate/
│   │   ├── _intermediate.yml
│   │   ├── int_customers_deduplicated.sql
│   │   └── int_orders_deduplicated.sql
│   └── marts/
│       ├── _marts.yml
│       ├── dim_customers.sql
│       ├── fct_orders.sql
│       ├── customer_order_summary.sql
│       └── daily_sales.sql
├── tests/
│   └── assert_non_negative_order_totals.sql
└── setup/
    ├── 01_setup_snowflake.sql
    ├── 02_add_incremental_orders.sql
    ├── 03_verify_outputs.sql
    └── 04_optional_cleanup.sql
```

There is intentionally no `packages.yml`. Built-in generic tests and one
singular test are sufficient for this introduction, and avoiding remote
packages means no external access integration or `dbt deps` step is required.

## Security and object layout

`setup/01_setup_snowflake.sql` creates `DBT_DEVELOPER` beneath `SYSADMIN`.
`DBT_DEVELOPER` receives:

- read-only access to `LOAD_TRANSFORM_SERVE.BRONZE`;
- ownership of the isolated `DBT_ONBOARDING` database;
- usage of the X-Small `DBT_WH`; and
- no write privileges on Bronze, Silver, or Gold.

The profile target is `DBT_ONBOARDING.DEV`. dbt's default custom-schema naming
combines that target with each configured model layer:

| Project layer | Snowflake schema | Default materialization |
|---|---|---|
| staging | `DEV_STAGING` | view |
| intermediate | `DEV_INTERMEDIATE` | view |
| marts | `DEV_MARTS` | table, except incremental `FCT_ORDERS` |

The deployed project object is stored separately as
`DBT_ONBOARDING.PROJECTS.ONBOARDING_ANALYTICS`.

## Prerequisites

Use Snowsight with access to **Projects → Workspaces** and keep the local
`09_dbt_integration` folder available for import. After running the environment
setup, use the `DBT_DEVELOPER` role for the workspace, project deployment, and
dbt execution.

Do not add credentials to `profiles.yml`. A Snowflake-native dbt project runs
under the current Snowflake account and user, so the committed profile contains
only its role, database, schema, warehouse, and thread count.

## 1. Create the Snowflake environment

Run `setup/01_setup_snowflake.sql` from a Snowsight worksheet. It switches among
the narrowly scoped administrative and owner roles required for each operation,
then finishes as `DBT_DEVELOPER`.

No task, Git integration, external access integration, resource monitor, or
budget is required for this introductory project.

## 2. Create a dbt project from the local files

In Snowsight:

1. Open **Projects → Workspaces**.
2. Select **Create new dbt project**.
3. Choose the option to create the project from local files.
4. Select the complete `09_dbt_integration` folder, not only its `models`
   subfolder.
5. Confirm that Snowsight detects `dbt_project.yml`, `profiles.yml`, the model
   directories, and the `tests` directory.
6. Confirm that the active role is `DBT_DEVELOPER`, the project is
   `onboarding_analytics`, and the profile target is `dev`.

The setup SQL files are imported with the project for convenience, but they are
not dbt models because they are outside the configured `model-paths`.

## 3. Compile before executing

Compilation resolves `source()`, `ref()`, Jinja, incremental branches, and
schema naming without materializing the model graph:

1. In the workspace command selector, choose **dbt compile**.
2. Keep the `dev` profile target selected.
3. Select **Execute**.
4. Open the **Output** tab and confirm that compilation succeeds.
5. Open a model and compare its source SQL with **View compiled SQL**.

Notice that `source()` resolves to `LOAD_TRANSFORM_SERVE.BRONZE`, while `ref()`
resolves to objects in the generated development schemas.

## 4. Deploy the project object

Compilation validates the workspace files, but it does not create the versioned
Snowflake project object. Deploy the successfully compiled project:

1. Select **Connect → Deploy dbt project**.
2. Select database `DBT_ONBOARDING` and schema `PROJECTS`.
3. Create a dbt project object named `ONBOARDING_ANALYTICS`.
4. Set the default target to `dev`.
5. Deploy the project.

The deployment creates version 1 of
`DBT_ONBOARDING.PROJECTS.ONBOARDING_ANALYTICS`. Deployment versions the project
code; it does not materialize the models.

## 5. Build models and tests

Return to the workspace command selector, choose **dbt build**, keep target
`dev`, and select **Execute**.

Use `build`, rather than separate `run` and `test` operations. dbt builds and
tests nodes in DAG order, preventing invalid upstream data from silently
propagating into downstream marts.

The build exercises:

- `source()` declarations for Bronze;
- `ref()`-based dependency ordering;
- source-conformed staging views;
- intermediate deduplication views;
- mart table materializations;
- the first full creation of an incremental model;
- `not_null`, `unique`, `accepted_values`, and `relationships` tests; and
- a singular test that rejects negative or over-discounted orders.

After the run, inspect the DAG and expand its columns. Column-level lineage
appears only after Snowflake has materialized the models at least once.

You can also open an individual model and select its play button to execute only
that model. For the complete workshop graph, the explicit **dbt build**
operation remains the preferred choice.

## 6. Demonstrate an incremental merge

Run `setup/02_add_incremental_orders.sql` once. It appends:

- order `59999`, which exercises the `WHEN NOT MATCHED` path; and
- a later `DELIVERED` version of order `50015`, which exercises the
  `WHEN MATCHED` update path.

Then build the incremental fact and every downstream model:

1. Choose **dbt build** in the workspace command selector.
2. Add `--select fct_orders+` under **Additional flags**.
3. Keep target `dev` selected and execute the command.

`fct_orders` filters the deduplicated intermediate orders by
`BRONZE_LOADED_AT` during incremental runs. It deliberately uses `>=` rather
than `>` so rows sharing the current maximum timestamp are safely reconsidered;
Snowflake `MERGE` keeps the target idempotent by `ORDER_ID`.

## 7. Verify Snowflake objects

Run `setup/03_verify_outputs.sql`. Confirm that:

- staging nodes are views;
- intermediate nodes are views;
- all business-facing models are tables in the marts schema;
- order `59999` was inserted into `FCT_ORDERS`;
- order `50015` now has status `DELIVERED`; and
- the customer and daily marts reflect the incremental changes.

Also inspect the dbt execution in **Activity → Query History**. The individual
model statements use `DBT_WH`, while the dbt project details page provides the
run-level output, artifacts, DAG, and lineage.

## 8. Add a project version

Make a harmless change, such as improving a model or column description, then
compile the workspace again. Select **Connect → Redeploy dbt project** to add a
new immutable version to the existing `ONBOARDING_ANALYTICS` project object.
Redeployment preserves the existing project and its run history.

Open **Connect → View project**, or navigate to
**Transformations → dbt Projects → ONBOARDING_ANALYTICS**, to inspect the
deployed version, DAG, privileges, and run history.

## How this maps to production

The manual Snowsight workflow makes each lifecycle step visible during
onboarding. In an enterprise workflow, the project normally lives in Git:

- developers compile and build changes in isolated development environments;
- pull requests trigger automated CI builds and tests;
- merging an approved change triggers deployment of a new project version; and
- an orchestrator or Snowflake task executes production builds on a schedule.

Those automated systems can use Snowflake CLI or SQL as their machine
interface. Individual developers do not normally perform manual production
deployments from a terminal.

## Why this project remains small

The heavy Snowflake sample datasets are useful for Chapter 7 performance tests,
but they do not improve this dbt integration exercise. A small business graph
makes compilation, materialization, testing, incremental behavior, lineage, and
project versioning visible without introducing unrelated modeling complexity.

Snapshots, seeds, packages, macros, semantic models, and production scheduling
belong in the deeper dbt onboarding material. The Snowflake-native project
supports those features, but they are not required to understand the
integration boundary.

## References

- [dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake)
- [Workspaces for dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-using-workspaces)
- [Deploy dbt project objects](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-deploy)
- [Access control for dbt projects](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-access-control)
- [Supported dbt commands and flags](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-supported-commands)
- [Manage dbt project objects and DAGs](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-manage)
- [CI/CD for dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-ci-cd)
