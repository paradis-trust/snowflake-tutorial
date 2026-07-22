-- Chapter 6: Management
-- Configure two complementary controls:
--   1. Resource monitor: enforces limits on assigned warehouses.
--   2. Tag-based custom budget: monitors a broader tagged resource scope.

-- Resource monitor creation is restricted to ACCOUNTADMIN. Keep its scope on
-- the workshop warehouses; an account-level monitor could affect other teams.
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE RESOURCE MONITOR MANAGEMENT_LAB_MONITOR
  WITH CREDIT_QUOTA = 5
       FREQUENCY = MONTHLY
       START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 50 PERCENT DO NOTIFY
    ON 80 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND
    ON 110 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE MGMT_XS_WH
  SET RESOURCE_MONITOR = MANAGEMENT_LAB_MONITOR;
ALTER WAREHOUSE MGMT_SMALL_WH
  SET RESOURCE_MONITOR = MANAGEMENT_LAB_MONITOR;
ALTER WAREHOUSE MGMT_MEDIUM_WH
  SET RESOURCE_MONITOR = MANAGEMENT_LAB_MONITOR;

SHOW RESOURCE MONITORS LIKE 'MANAGEMENT_LAB_MONITOR';

-- Resource monitors control user-managed warehouses only. They do not monitor
-- serverless features such as Snowpipe or automatic clustering. Budgets monitor
-- and forecast a broader cost scope but do not suspend warehouses by default.

-- Allow MANAGEMENT_ADMIN to use the centrally governed COST_CENTER tag as the
-- scope of a custom budget. GOVERNANCE_ADMIN grants this capability but does
-- not create or own the budget.
USE ROLE GOVERNANCE_ADMIN;
USE DATABASE MANAGEMENT_LAB;
USE SCHEMA GOVERNANCE;

GRANT APPLYBUDGET ON TAG COST_CENTER TO ROLE MANAGEMENT_ADMIN;

-- ---------------------------------------------------------------------------
-- Create the custom budget in Snowsight
-- ---------------------------------------------------------------------------
-- Snowflake supports creating custom budgets with SQL, but Snowsight is the
-- primary workflow for this exercise because it provides governed tag/value
-- selectors and guides notification configuration.
--
-- 1. If the account budget is not active, use ACCOUNTADMIN in Snowsight and
--    open Admin -> Cost management -> Budgets to activate it first.
-- 2. Select the MANAGEMENT_ADMIN role in Snowsight.
-- 3. Open Admin -> Cost management -> Budgets and create a custom budget.
-- 4. Configure it with:
--      Name:           MANAGEMENT_DATA_PLATFORM_BUDGET
--      Database:       MANAGEMENT_LAB
--      Schema:         GOVERNANCE
--      Spending limit: 10 credits per month
-- 5. For the monitored resources, choose the tag-based option and select:
--      Tag:   MANAGEMENT_LAB.GOVERNANCE.COST_CENTER
--      Value: DATA_PLATFORM
-- 6. Optionally add a verified notification recipient, then save the budget.
--
-- A newly applied tag can take time to appear in the Snowsight selector. This
-- budget monitors and forecasts tagged consumption; it does not impose a hard
-- spending limit or suspend resources.

-- ---------------------------------------------------------------------------
-- Explore the Snowsight-created budget with SQL
-- ---------------------------------------------------------------------------
USE ROLE MANAGEMENT_ADMIN;
USE DATABASE MANAGEMENT_LAB;
USE SCHEMA GOVERNANCE;
USE WAREHOUSE MGMT_XS_WH;

SHOW SNOWFLAKE.CORE.BUDGET INSTANCES
  LIKE 'MANAGEMENT_DATA_PLATFORM_BUDGET'
  IN SCHEMA MANAGEMENT_LAB.GOVERNANCE;

CALL MANAGEMENT_LAB.GOVERNANCE.MANAGEMENT_DATA_PLATFORM_BUDGET!GET_CONFIG();
CALL MANAGEMENT_LAB.GOVERNANCE.MANAGEMENT_DATA_PLATFORM_BUDGET!GET_BUDGET_SCOPE();
