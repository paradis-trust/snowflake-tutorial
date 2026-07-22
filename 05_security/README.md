# Security workshop

This chapter applies role-based access control and governance policies to the
objects created in `../03_04_load_transform_serve/`.

Run the files in order:

1. `01_roles_and_hierarchy.sql` creates separated functional, object-owner, and `GOVERNANCE_ADMIN` roles beneath `SYSADMIN`. It then uses `ACCOUNTADMIN` once to transfer ownership of the objects created in Chapters 3 and 4.
2. `02_sensitive_data_and_policies.sql` creates separate `SECURITY` and `SENSITIVE` schemas. `GOVERNANCE_ADMIN` owns and centrally applies the salary, row-access, and tag-based email policies without receiving `SELECT` on the protected table. Separate `DATA_SENSITIVITY` and `PII_CATEGORY` tags model handling level and personal-data type independently.
3. `03_privileges_and_future_grants.sql` grants warehouse, database, schema, and object privileges, then configures future grants for new pipeline and serving objects.
4. `04_verify_role_access.sql` switches roles and compares visible schemas, rows, salary values, and tagged email values.

`SYSADMIN` and `SECURITYADMIN` are Snowflake system roles and are deliberately
not created by the workshop. Following Snowflake's recommended hierarchy, every
custom role is granted to `SYSADMIN`. This lets system administrators inherit
object privileges and administer custom-role objects. `SECURITYADMIN` manages
roles and grants through `MANAGE GRANTS`.

Inheritance does not create a policy exemption. Policies use exact
`CURRENT_ROLE()` checks, so a session whose active role is `SYSADMIN` or
`ACCOUNTADMIN` does not satisfy conditions written for `HR`, `FINANCE`, or
`DATA_ANALYST`. An administrator must deliberately activate an authorized
business role to receive that role's governed data visibility.

For convenience, the current learner receives every custom role directly and
the verification script disables secondary roles before every persona test. In
production, object ownership, governance, engineering, HR, Finance, and analyst
roles should be assigned to separate users or identity-provider groups.

Chapters 3 and 4 intentionally introduce Snowflake objects without requiring
RBAC setup first. Chapter 5 makes ownership explicit. `ACCOUNTADMIN` performs
only the one-time migration: it does not create schemas, tables, or policies.
The pipe is paused during migration. The new owner inspects its status and uses
`SYSTEM$PIPE_FORCE_RESUME` with an explicit ownership-transfer override because
Snowflake blocks an ordinary resume after ownership changes. Snowflake also
suspends tasks when their ownership changes, so the incremental task remains
suspended unless you deliberately resume it after the transfer.

Policy conditions use exact `CURRENT_ROLE()` checks rather than inherited-role
checks. Clear data therefore requires deliberately activating `HR` or
`FINANCE`; merely having one of those roles available as a secondary role does
not unmask data.

Sensitive compensation data is stored in `SENSITIVE`, not `GOLD`. Broad future
grants remain useful for ordinary curated data without automatically exposing
future sensitive tables. Access to `SENSITIVE.EMPLOYEE_COMPENSATION` is always
an explicit grant.

The tag taxonomy has two independent dimensions:

- `DATA_SENSITIVITY`: `PUBLIC`, `INTERNAL`, `CONFIDENTIAL`, or `RESTRICTED`.
- `PII_CATEGORY`: `DIRECT_IDENTIFIER`, `QUASI_IDENTIFIER`, or
  `SENSITIVE_PERSONAL_DATA`. An untagged column is not classified as PII.

For example, `EMAIL` is both `RESTRICTED` and a `DIRECT_IDENTIFIER`, while
`SALARY` is both `RESTRICTED` and `SENSITIVE_PERSONAL_DATA`. Tag-based string
masking is attached to `PII_CATEGORY`; sensitivity remains available for data
handling, discovery, and future governance policies.

The examples use `COMPUTE_WH`; replace it if your account uses a different
warehouse. Dynamic data masking, row access policies, and tag-based masking
require Snowflake Enterprise Edition or higher.

Expected compensation-table results:

| Role | Visible rows | Salary | Email |
| --- | --- | --- | --- |
| `DATA_ANALYST` | All departments | Masked as `NULL` | `***MASKED***` |
| `FINANCE` | Finance only | Visible | `***MASKED***` |
| `HR` | All departments | Visible | Visible |
| `DATA_ENGINEER` | No table access | — | — |
| `LOAD_TRANSFORM_SERVE_OWNER` | No rows | — | — |
| `GOVERNANCE_ADMIN` | No table access | — | — |
| `SYSADMIN` / `ACCOUNTADMIN` | No rows through policy | — | — |
| `SECURITYADMIN` | No table access | — | — |

The deliberately unauthorized bronze query in the verification script is
commented out so the workshop can run to completion. Execute it separately to
observe the access-control error for `DATA_ANALYST`.
