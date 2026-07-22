-- Chapter 5: Security
-- Create sensitive workshop data, governance policies, and a classification
-- tag. Complete the loading and transformation chapters first.

-- The dedicated object-owner role created in 01_roles_and_hierarchy.sql now
-- owns the database. ACCOUNTADMIN is no longer needed for application objects.
USE ROLE LOAD_TRANSFORM_SERVE_OWNER;
USE DATABASE LOAD_TRANSFORM_SERVE;

CREATE SCHEMA IF NOT EXISTS SECURITY
  COMMENT = 'Central location for governance policies and tags';

-- Sensitive data has its own schema instead of sharing GOLD, where broad
-- analytics grants and future grants are appropriate.
CREATE SCHEMA IF NOT EXISTS SENSITIVE
  COMMENT = 'Restricted business data protected by governance policies';

-- Reuse sample people from SILVER_CUSTOMERS to create a fictional employee
-- dataset. The salary and department fields exist only for this workshop.
CREATE OR REPLACE TABLE SENSITIVE.EMPLOYEE_COMPENSATION AS
WITH RANKED_PEOPLE AS (
  SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    COUNTRY,
    SIGNUP_DATE,
    ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID) AS RN
  FROM SILVER.SILVER_CUSTOMERS
)
SELECT
  CUSTOMER_ID AS EMPLOYEE_ID,
  FIRST_NAME,
  LAST_NAME,
  EMAIL,
  COUNTRY,
  CASE MOD(RN - 1, 4)
    WHEN 0 THEN 'Finance'
    WHEN 1 THEN 'HR'
    WHEN 2 THEN 'Engineering'
    ELSE 'Sales'
  END AS DEPARTMENT,
  CASE MOD(RN - 1, 4)
    WHEN 0 THEN 'Financial Analyst'
    WHEN 1 THEN 'People Partner'
    WHEN 2 THEN 'Data Engineer'
    ELSE 'Account Executive'
  END AS JOB_TITLE,
  SIGNUP_DATE AS HIRE_DATE,
  (65000 + MOD(CUSTOMER_ID, 10) * 5000)::NUMBER(12, 2) AS SALARY
FROM RANKED_PEOPLE
WHERE RN <= 16;

-- The object owner delegates only governance-object creation and metadata
-- visibility to the isolated policy-administration role. It grants no SELECT
-- privilege on the protected table.
GRANT USAGE ON DATABASE LOAD_TRANSFORM_SERVE TO ROLE GOVERNANCE_ADMIN;
GRANT USAGE ON SCHEMA LOAD_TRANSFORM_SERVE.SECURITY TO ROLE GOVERNANCE_ADMIN;
GRANT USAGE ON SCHEMA LOAD_TRANSFORM_SERVE.SENSITIVE TO ROLE GOVERNANCE_ADMIN;
GRANT CREATE MASKING POLICY, CREATE ROW ACCESS POLICY, CREATE TAG
  ON SCHEMA LOAD_TRANSFORM_SERVE.SECURITY
  TO ROLE GOVERNANCE_ADMIN;

USE ROLE GOVERNANCE_ADMIN;
USE DATABASE LOAD_TRANSFORM_SERVE;
USE SCHEMA SECURITY;

-- Only the business roles with a legitimate need see exact salaries. Exact
-- CURRENT_ROLE checks require the user to activate that persona deliberately;
-- an administrator does not become authorized through secondary roles.
CREATE OR REPLACE MASKING POLICY SALARY_MASKING_POLICY
AS (VALUE NUMBER(12, 2)) RETURNS NUMBER(12, 2) ->
  CASE
    WHEN CURRENT_ROLE() IN ('HR', 'FINANCE') THEN VALUE
    ELSE NULL
  END
COMMENT = 'Masks exact salary values from non-HR and non-Finance roles';

-- HR and approved workforce analysts see all departments. FINANCE sees only
-- Finance rows. Object owners and system administrators see no rows unless
-- they explicitly assume an authorized business role.
CREATE OR REPLACE ROW ACCESS POLICY DEPARTMENT_ROW_ACCESS_POLICY
AS (ROW_DEPARTMENT VARCHAR) RETURNS BOOLEAN ->
  CASE
    WHEN CURRENT_ROLE() IN ('HR', 'DATA_ANALYST') THEN TRUE
    WHEN CURRENT_ROLE() = 'FINANCE' THEN ROW_DEPARTMENT = 'Finance'
    ELSE FALSE
  END
COMMENT = 'Restricts FINANCE to Finance compensation rows';

-- Sensitivity and PII are independent dimensions. A value can be both
-- RESTRICTED and a DIRECT_IDENTIFIER, so they must not share one tag.
CREATE OR REPLACE TAG DATA_SENSITIVITY
  ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED'
  COMMENT = 'Defines the handling and disclosure level of data';

-- Absence of this tag means the column is not classified as PII. Tagged
-- columns describe the kind of personal information they contain.
CREATE OR REPLACE TAG PII_CATEGORY
  ALLOWED_VALUES 'DIRECT_IDENTIFIER', 'QUASI_IDENTIFIER',
                 'SENSITIVE_PERSONAL_DATA'
  COMMENT = 'Classifies the type of personally identifiable information';

CREATE OR REPLACE MASKING POLICY PII_STRING_MASKING_POLICY
AS (VALUE VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN(
      'LOAD_TRANSFORM_SERVE.SECURITY.PII_CATEGORY'
    ) IS NULL THEN VALUE
    WHEN CURRENT_ROLE() = 'HR' THEN VALUE
    ELSE '***MASKED***'
  END
COMMENT = 'Masks VARCHAR columns classified with a PII category';

ALTER TAG PII_CATEGORY
  SET MASKING POLICY PII_STRING_MASKING_POLICY;

-- Centralized governance applies every control. The table owner receives no
-- APPLY privilege and therefore cannot casually unset these protections.
ALTER TABLE SENSITIVE.EMPLOYEE_COMPENSATION
  MODIFY COLUMN SALARY
  SET MASKING POLICY SECURITY.SALARY_MASKING_POLICY;

ALTER TABLE SENSITIVE.EMPLOYEE_COMPENSATION
  ADD ROW ACCESS POLICY SECURITY.DEPARTMENT_ROW_ACCESS_POLICY
  ON (DEPARTMENT);

ALTER TABLE SENSITIVE.EMPLOYEE_COMPENSATION
  MODIFY COLUMN EMAIL
  SET TAG SECURITY.DATA_SENSITIVITY = 'RESTRICTED';

ALTER TABLE SENSITIVE.EMPLOYEE_COMPENSATION
  MODIFY COLUMN EMAIL
  SET TAG SECURITY.PII_CATEGORY = 'DIRECT_IDENTIFIER';

-- Salary is restricted sensitive personal data. Its NUMBER masking behavior is
-- provided by the direct salary policy; the tags remain useful for discovery,
-- auditing, and classification independently of that implementation.
ALTER TABLE SENSITIVE.EMPLOYEE_COMPENSATION
  MODIFY COLUMN SALARY
  SET TAG SECURITY.DATA_SENSITIVITY = 'RESTRICTED';

ALTER TABLE SENSITIVE.EMPLOYEE_COMPENSATION
  MODIFY COLUMN SALARY
  SET TAG SECURITY.PII_CATEGORY = 'SENSITIVE_PERSONAL_DATA';

ALTER TABLE SENSITIVE.EMPLOYEE_COMPENSATION
  MODIFY COLUMN DEPARTMENT
  SET TAG SECURITY.DATA_SENSITIVITY = 'INTERNAL';

-- Ownership does not bypass the row policy: this returns zero rows while the
-- owner role is active. The owner can maintain the object but is not a data
-- consumption persona.
USE ROLE LOAD_TRANSFORM_SERVE_OWNER;

SELECT COUNT(*) AS ROWS_VISIBLE_TO_OBJECT_OWNER
FROM SENSITIVE.EMPLOYEE_COMPENSATION;
