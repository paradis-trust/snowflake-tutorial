-- Chapter 6: Management
-- Create a writable zero-copy DEV database from the workshop database.

-- SYSADMIN has CREATE DATABASE and inherits the source owner's privileges.
USE ROLE SYSADMIN;

CREATE OR REPLACE DATABASE LOAD_TRANSFORM_SERVE_DEV
  CLONE LOAD_TRANSFORM_SERVE;

COMMENT ON DATABASE LOAD_TRANSFORM_SERVE_DEV IS
  'Zero-copy development clone of LOAD_TRANSFORM_SERVE';

-- Governance classification is explicit for the new environment. The clone
-- remains in the DATA_PLATFORM cost center but must not retain TRAINING as its
-- environment classification.
USE ROLE GOVERNANCE_ADMIN;

ALTER DATABASE LOAD_TRANSFORM_SERVE_DEV SET TAG
  MANAGEMENT_LAB.GOVERNANCE.COST_CENTER = 'DATA_PLATFORM',
  MANAGEMENT_LAB.GOVERNANCE.ENVIRONMENT = 'DEV';

USE ROLE SYSADMIN;

-- Container grants are not copied to the cloned database, while grants on
-- cloned child objects have special inheritance behavior. Always audit access
-- rather than assuming PROD and DEV have identical RBAC.
SHOW GRANTS ON DATABASE LOAD_TRANSFORM_SERVE_DEV;
SHOW SCHEMAS IN DATABASE LOAD_TRANSFORM_SERVE_DEV;
SHOW TASKS IN SCHEMA LOAD_TRANSFORM_SERVE_DEV.SILVER;
SHOW DYNAMIC TABLES IN SCHEMA LOAD_TRANSFORM_SERVE_DEV.GOLD;
SHOW PIPES IN SCHEMA LOAD_TRANSFORM_SERVE_DEV.BRONZE;

-- Cloned tasks and dynamic tables are suspended by default. The source pipe
-- references an internal stage, so Snowflake does not clone that pipe. Named
-- internal stage files are also excluded unless INCLUDE INTERNAL STAGES is
-- requested explicitly. These defaults help avoid accidental DEV ingestion.

-- Prove that clone and source are writable independently.
CREATE OR REPLACE TABLE LOAD_TRANSFORM_SERVE_DEV.GOLD.DEV_CLONE_PROOF AS
SELECT CURRENT_TIMESTAMP() AS CREATED_AT, 'DEV ONLY' AS ENVIRONMENT;

SELECT * FROM LOAD_TRANSFORM_SERVE_DEV.GOLD.DEV_CLONE_PROOF;

-- Expected to fail because the DEV-only table does not exist in the source.
SELECT * FROM LOAD_TRANSFORM_SERVE.GOLD.DEV_CLONE_PROOF;

-- Environment-specific follow-up normally includes dedicated DEV warehouses,
-- reduced retention, task schedules, integrations, and RBAC.
ALTER DATABASE LOAD_TRANSFORM_SERVE_DEV SET DATA_RETENTION_TIME_IN_DAYS = 1;
