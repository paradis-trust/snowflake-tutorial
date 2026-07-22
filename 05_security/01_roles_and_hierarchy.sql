-- Chapter 5: Security
-- Introduce RBAC, create separated roles, and transfer the workshop objects
-- created in Chapters 3 and 4 to a dedicated owner role.
--
-- Complete Chapters 3 and 4 first. This script intentionally uses
-- ACCOUNTADMIN only for the one-time ownership migration.

USE ROLE SECURITYADMIN;

-- SYSADMIN and SECURITYADMIN are system-defined Snowflake roles. They already
-- exist and must not be recreated. SECURITYADMIN inherits USERADMIN, creates
-- the custom roles, and manages grants without inheriting their data access.
SHOW ROLES LIKE 'SYSADMIN';
SHOW ROLES LIKE 'SECURITYADMIN';

CREATE ROLE IF NOT EXISTS DATA_ENGINEER
  COMMENT = 'Builds and operates bronze, silver, and gold data pipelines';

CREATE ROLE IF NOT EXISTS DATA_ANALYST
  COMMENT = 'Queries curated silver and gold data';

CREATE ROLE IF NOT EXISTS FINANCE
  COMMENT = 'Queries finance-serving data and Finance compensation rows';

CREATE ROLE IF NOT EXISTS HR
  COMMENT = 'Queries employee and compensation data';

-- This access role owns the LOAD_TRANSFORM_SERVE database and its existing
-- objects. It is not a day-to-day data-consumption role.
CREATE ROLE IF NOT EXISTS LOAD_TRANSFORM_SERVE_OWNER
  COMMENT = 'Owns the LOAD_TRANSFORM_SERVE database and its objects';

-- Policy ownership is separated from both system administration and data
-- ownership. Policies run with their owner's rights, so a custom governance
-- role avoids making SECURITYADMIN the policy execution context.
CREATE ROLE IF NOT EXISTS GOVERNANCE_ADMIN
  COMMENT = 'Owns and administers masking policies, row policies, and tags';

-- Snowflake recommends placing custom roles below SYSADMIN. SYSADMIN inherits
-- their object privileges and can administer the objects they own. Sensitive
-- policies still use exact CURRENT_ROLE checks, so activating SYSADMIN does not
-- make the session HR, FINANCE, or DATA_ANALYST for policy evaluation.
GRANT ROLE DATA_ENGINEER TO ROLE SYSADMIN;
GRANT ROLE DATA_ANALYST TO ROLE SYSADMIN;
GRANT ROLE FINANCE TO ROLE SYSADMIN;
GRANT ROLE HR TO ROLE SYSADMIN;
GRANT ROLE LOAD_TRANSFORM_SERVE_OWNER TO ROLE SYSADMIN;
GRANT ROLE GOVERNANCE_ADMIN TO ROLE SYSADMIN;

-- Give one learner direct access to each role so the verification script can
-- switch personas. In production, owner, governance, and business roles belong
-- to separate service users or identity-provider groups.
SET workshop_user = CURRENT_USER();

GRANT ROLE DATA_ENGINEER TO USER IDENTIFIER($workshop_user);
GRANT ROLE DATA_ANALYST TO USER IDENTIFIER($workshop_user);
GRANT ROLE FINANCE TO USER IDENTIFIER($workshop_user);
GRANT ROLE HR TO USER IDENTIFIER($workshop_user);
GRANT ROLE LOAD_TRANSFORM_SERVE_OWNER TO USER IDENTIFIER($workshop_user);
GRANT ROLE GOVERNANCE_ADMIN TO USER IDENTIFIER($workshop_user);

-- A dynamic table's receiving owner must already be able to use its database,
-- schema, and refresh warehouse. These grants also let the owner create the
-- protected table in the next script. Ownership supersedes USAGE after the
-- database and schemas themselves are transferred.
GRANT USAGE ON DATABASE LOAD_TRANSFORM_SERVE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER;
GRANT USAGE ON SCHEMA LOAD_TRANSFORM_SERVE.BRONZE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER;
GRANT USAGE ON SCHEMA LOAD_TRANSFORM_SERVE.SILVER
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER;
GRANT USAGE ON SCHEMA LOAD_TRANSFORM_SERVE.GOLD
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER;
GRANT USAGE ON WAREHOUSE COMPUTE_WH
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER;
GRANT USAGE ON WAREHOUSE COMPUTE_WH
  TO ROLE GOVERNANCE_ADMIN;
GRANT EXECUTE TASK ON ACCOUNT
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER;

-- Centralized governance can attach and remove protection without owning the
-- protected objects. These privileges grant no SELECT or data visibility.
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE GOVERNANCE_ADMIN;
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE GOVERNANCE_ADMIN;
GRANT APPLY TAG ON ACCOUNT TO ROLE GOVERNANCE_ADMIN;

-- ---------------------------------------------------------------------------
-- One-time migration from the role that created the earlier workshop objects
-- ---------------------------------------------------------------------------
-- ACCOUNTADMIN is appropriate here because the original objects may have been
-- created by different active roles. It is not used to create application
-- schemas, tables, or policies in this chapter.
USE ROLE ACCOUNTADMIN;

-- A pipe must be paused before ownership can be transferred. Restore it after
-- the transfer so manual Snowpipe remains usable.
ALTER PIPE LOAD_TRANSFORM_SERVE.BRONZE.BRONZE_DEVICE_READINGS_PIPE
  SET PIPE_EXECUTION_PAUSED = TRUE;

-- Transfer contained objects before their schemas, then transfer the database.
-- COPY CURRENT GRANTS preserves any privileges already granted on an object.
GRANT OWNERSHIP ON ALL TABLES IN SCHEMA LOAD_TRANSFORM_SERVE.BRONZE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL STAGES IN SCHEMA LOAD_TRANSFORM_SERVE.BRONZE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL FILE FORMATS IN SCHEMA LOAD_TRANSFORM_SERVE.BRONZE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
-- Snowflake does not support bulk ownership grants for pipes.
GRANT OWNERSHIP ON PIPE LOAD_TRANSFORM_SERVE.BRONZE.BRONZE_DEVICE_READINGS_PIPE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL STREAMS IN SCHEMA LOAD_TRANSFORM_SERVE.BRONZE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL TABLES IN SCHEMA LOAD_TRANSFORM_SERVE.SILVER
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL TASKS IN SCHEMA LOAD_TRANSFORM_SERVE.SILVER
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;

GRANT OWNERSHIP ON ALL TABLES IN SCHEMA LOAD_TRANSFORM_SERVE.GOLD
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL DYNAMIC TABLES IN SCHEMA LOAD_TRANSFORM_SERVE.GOLD
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON VIEW LOAD_TRANSFORM_SERVE.GOLD.VW_CUSTOMER_ORDER_SUMMARY
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
-- Snowflake uses VIEW, rather than MATERIALIZED VIEW, in GRANT OWNERSHIP.
GRANT OWNERSHIP ON VIEW LOAD_TRANSFORM_SERVE.GOLD.MV_ORDERS_BY_COUNTRY
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON VIEW LOAD_TRANSFORM_SERVE.GOLD.SECURE_DAILY_SALES
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;

GRANT OWNERSHIP ON SCHEMA LOAD_TRANSFORM_SERVE.BRONZE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA LOAD_TRANSFORM_SERVE.SILVER
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA LOAD_TRANSFORM_SERVE.GOLD
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA LOAD_TRANSFORM_SERVE.PUBLIC
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;
GRANT OWNERSHIP ON DATABASE LOAD_TRANSFORM_SERVE
  TO ROLE LOAD_TRANSFORM_SERVE_OWNER COPY CURRENT GRANTS;

-- Activate the intended owner instead of relying on privileges inherited by
-- SYSADMIN and ACCOUNTADMIN. Snowflake deliberately blocks a normal resume
-- after ownership changes. Inspect the queue before explicitly accepting files
-- submitted under the previous owner. This workshop controls its internal stage,
-- so those files are expected and the ownership-transfer override is safe.
USE ROLE LOAD_TRANSFORM_SERVE_OWNER;

SELECT SYSTEM$PIPE_STATUS(
  'LOAD_TRANSFORM_SERVE.BRONZE.BRONZE_DEVICE_READINGS_PIPE'
);

SELECT SYSTEM$PIPE_FORCE_RESUME(
  'LOAD_TRANSFORM_SERVE.BRONZE.BRONZE_DEVICE_READINGS_PIPE',
  'OWNERSHIP_TRANSFER_CHECK_OVERRIDE'
);

SELECT SYSTEM$PIPE_STATUS(
  'LOAD_TRANSFORM_SERVE.BRONZE.BRONZE_DEVICE_READINGS_PIPE'
);

-- Task ownership transfer suspends tasks. That is safe for this workshop. If
-- you previously enabled the task, resume it deliberately after Chapter 5:
-- USE ROLE LOAD_TRANSFORM_SERVE_OWNER;
-- ALTER TASK LOAD_TRANSFORM_SERVE.SILVER.SILVER_ORDERS_INCREMENTAL_TASK RESUME;

USE ROLE SECURITYADMIN;

SHOW GRANTS OF ROLE DATA_ENGINEER;
SHOW GRANTS OF ROLE DATA_ANALYST;
SHOW GRANTS OF ROLE FINANCE;
SHOW GRANTS OF ROLE HR;
SHOW GRANTS OF ROLE LOAD_TRANSFORM_SERVE_OWNER;
SHOW GRANTS OF ROLE GOVERNANCE_ADMIN;
SHOW GRANTS TO ROLE LOAD_TRANSFORM_SERVE_OWNER;
SHOW GRANTS TO ROLE GOVERNANCE_ADMIN;
