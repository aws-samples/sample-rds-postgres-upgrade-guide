# PostgreSQL Upgrade Guide
Resources from the 2026 talk: **"Is Your Database Keeping Up?"**

## Start here → run this first

```sql
SELECT version();
```

Run it across every environment — dev, staging, production.
Then work your way through the sections below.

---

## Section 1 — Know Where You Stand

### Check version inside any PostgreSQL instance

📄 Script: [scripts/sql/01-check-version.sql](scripts/sql/01-check-version.sql)

```sql
-- Human-readable version
SELECT version();

-- Numeric version (useful for scripting comparisons)
SELECT current_setting('server_version_num');
```

### Check all your RDS instances at once (AWS CLI)

📄 Script: [scripts/bash/01-check-rds-instances.sh](scripts/bash/01-check-rds-instances.sh)

```bash
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,EngineVersion,DBInstanceStatus]' \
  --output table
```

### Check across multiple environments in one script

📄 Script: [scripts/bash/02-check-multi-env.sh](scripts/bash/02-check-multi-env.sh)

```bash
#!/bin/bash
# environments.sh — add your connection strings below
ENVS=(
  "host=dev-db.example.com dbname=myapp user=postgres"
  "host=staging-db.example.com dbname=myapp user=postgres"
  "host=prod-db.example.com dbname=myapp user=postgres"
)

for ENV in "${ENVS[@]}"; do
  echo "--- $ENV ---"
  psql "$ENV" -c "SELECT version();"
done
```

---

## Section 2 — Understand Your EOL Risk

Rather than maintaining a static table here that may become outdated, always refer directly to the official AWS documentation for the latest support dates — including community EOL, RDS standard support end, extended support start/end, and pricing tier changes.

**RDS for PostgreSQL release calendar (standard + extended support dates):**
👉 https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html

**Aurora PostgreSQL release calendar (standard + extended support dates):**
👉 https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html

**Key things to check in the table:**
- `Community end of life date` — when the open source community stops patching
- `RDS end of standard support date` — when AWS standard support ends
- `RDS start of Extended Support year 1 pricing` — when additional charges begin
- `RDS start of Extended Support year 3 pricing` — when charges increase further
- `RDS end of Extended Support date` — hard deadline, no more patches after this

> **Tip:** You can also query support dates programmatically via the AWS CLI:
> ```bash
> aws rds describe-db-major-engine-versions --engine postgres
> ```

---

## Section 3 — Prerequisites Check Before You Upgrade

Before planning your upgrade path, run through these prerequisite checks. Skipping these is the most common reason upgrades fail or roll back mid-process.

### 1. Unsupported DB instance classes for the target version

Some older instance types are not supported on newer PostgreSQL major versions. Verify your instance class is compatible with your target version before starting.

📄 Script: [scripts/bash/03-check-upgrade-targets.sh](scripts/bash/03-check-upgrade-targets.sh)

```bash
# Check which versions you can upgrade to directly from your current version
aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version <your-current-version> \
  --query 'DBEngineVersions[*].ValidUpgradeTarget[*].{Version:EngineVersion,MajorUpgrade:IsMajorVersionUpgrade}' \
  --output table
```

👉 RDS: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html
👉 Aurora: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html

### 2. Invalid databases

RDS runs a precheck before any major version upgrade using `pg_upgrade`. Invalid databases, open prepared transactions, or active logical replication slots will cause the upgrade to fail.

📄 Script: [scripts/sql/02-prereq-invalid-databases.sql](scripts/sql/02-prereq-invalid-databases.sql)

```sql
-- Check for invalid databases (datistemplate should be 't' for template0 and template1)
SELECT datname, datistemplate, datallowconn
FROM pg_database;

-- Check for open prepared transactions (must be zero before upgrading)
SELECT count(*) FROM pg_catalog.pg_prepared_xacts;

-- Check for active logical replication slots (must be dropped before upgrading)
SELECT * FROM pg_replication_slots WHERE slot_type NOT LIKE 'physical';
```

> If logical replication slots are in use, confirm their purpose before dropping.
> Dropping an active slot will cause replication consumers to lose their position.

```sql
-- Drop a replication slot only after confirming it is safe to do so
SELECT pg_drop_replication_slot('slot_name');
```

### 3. Unsupported data types

Certain data types used in older PostgreSQL versions are not supported in newer versions. The most common issues are the `unknown` data type (versions 9.x to 10+) and `reg*` data types.

📄 Script: [scripts/sql/03-prereq-unsupported-datatypes.sql](scripts/sql/03-prereq-unsupported-datatypes.sql)

```sql
-- Check for reg* data type usage (except regtype and regclass which are safe)
SELECT n.nspname AS schema, c.relname AS table, a.attname AS column, t.typname AS type
FROM pg_attribute a
JOIN pg_class c ON a.attrelid = c.oid
JOIN pg_type t ON a.atttypid = t.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.typname IN ('regproc','regprocedure','regoper','regoperator','regconfig','regdictionary')
  AND c.relkind = 'r'
  AND NOT a.attisdropped;
```

👉 Full list of pre-upgrade checks and common errors:
https://repost.aws/knowledge-center/rds-postgresql-version-upgrade-issues

### 4. Disk space

Major version upgrades require additional disk space during the process. Ensure you have at least as much free space as your current database size before starting.

📄 Script: [scripts/sql/04-prereq-disk-space.sql](scripts/sql/04-prereq-disk-space.sql)

```sql
-- Check current database sizes
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Check total size of the current database
SELECT pg_size_pretty(pg_database_size(current_database())) AS total_size;
```

### 5. Release dates between source and target version

Check that the target minor version is already available on RDS or Aurora before scheduling your upgrade. Not all community releases are immediately available on RDS.

📄 Script: [scripts/bash/04-list-available-versions.sh](scripts/bash/04-list-available-versions.sh)

```bash
# List all available PostgreSQL versions on RDS
aws rds describe-db-engine-versions \
  --engine postgres \
  --query 'DBEngineVersions[*].EngineVersion' \
  --output table
```

👉 Minor version release calendar:
https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html

### 6. Learn about limitations and best practices for your chosen upgrade approach

Each upgrade approach has its own constraints. Before finalising your upgrade strategy, read the documentation for the method you have chosen (see Section 7) and factor these into your plan — especially around logical replication slots, Multi-AZ behaviour, read replicas, parameter group compatibility, and extension handling.

---

## Section 4 — Check Your Extensions

Extensions are one of the most common causes of upgrade failures or post-upgrade issues. Always audit your extensions before upgrading.

### List all installed extensions

📄 Script: [scripts/sql/05-check-extensions.sql](scripts/sql/05-check-extensions.sql)

```sql
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE installed_version IS NOT NULL
ORDER BY name;
```

### Extensions that commonly require action before or after a major upgrade

| Extension | What to check | Typical action required |
|-----------|--------------|------------------------|
| **PostGIS** | Version compatibility with target PG version | Upgrade PostGIS *before* the engine upgrade in some cases. Follow the specific PostGIS upgrade steps in AWS docs. |
| **pgvector** | Availability on target version | Verify the version is available on the target. Run `ALTER EXTENSION vector UPDATE;` after upgrade. |
| **pg_repack** | Not compatible across major versions | Drop the extension before upgrading. Reinstall on the new version with `CREATE EXTENSION pg_repack;`. |
| **pg_cron** | Parameter group settings | Verify `cron.database_name` parameter is correctly set in the new parameter group after upgrade. |
| **pglogical** | Logical replication dependency | Check for conflicts with logical replication slots before upgrading. |
| **TimescaleDB** | Strict version compatibility | Consult the Timescale compatibility matrix. May require a specific upgrade sequence separate from the engine upgrade. |

> AWS does not automatically upgrade extensions when you upgrade the engine.
> For most extensions, run `ALTER EXTENSION name UPDATE;` after the engine upgrade.
> However, some extensions (like PostGIS) must be upgraded *before* the engine upgrade.
> Always check the specific guidance for each extension before proceeding.

**Official AWS extension references:**

👉 RDS for PostgreSQL extension versions:
https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-extensions.html

👉 Aurora PostgreSQL extension versions:
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html

👉 Upgrading extensions in Aurora PostgreSQL:
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.Upgrading.ExtensionUpgrades.html

---

## Section 5 — Plan Your Upgrade Strategy

### Step 1 — OS Update Consideration

For RDS and Aurora, AWS manages the underlying OS — no action required on your part. For self-managed PostgreSQL on EC2, plan OS updates separately from the database upgrade and never upgrade both at the same time in production.

### Step 2 — Minor Version Strategy

Decide upfront how you will handle minor version upgrades:

- **Option A — Enable Automatic Minor Version Upgrade (AMVU)** on RDS: AWS applies minor patches during your maintenance window automatically. Best for teams who want hands-off security patching with minimal operational overhead.
- **Option B — Manual minor version upgrades**: You control when patches are applied. Best for teams with strict change management or compliance requirements. If you choose this, build it into your maintenance schedule — do not let minor versions drift.

> Check current minor version availability before planning:
> https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html

### Step 3 — Major Version Upgrade Path

RDS and Aurora support skipping major versions in some upgrade paths — sequential upgrades are not always required. However, not every version-to-version jump is supported as a direct upgrade, and the available paths depend on your current version.

**Always verify the exact upgrade targets available for your specific version:**

📄 Script: [scripts/bash/03-check-upgrade-targets.sh](scripts/bash/03-check-upgrade-targets.sh)

```bash
# Check which versions you can upgrade to directly from your current version
aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version <your-current-version> \
  --query 'DBEngineVersions[*].ValidUpgradeTarget[*].{Version:EngineVersion,MajorUpgrade:IsMajorVersionUpgrade}' \
  --output table
```

If your target version is not available as a direct upgrade, an intermediate hop may be required. Test the full path in a non-production environment before scheduling production.

### Pre-Upgrade Checklist

```
[ ] Run SELECT version() across all environments — document current versions
[ ] Check valid upgrade targets for your current version (CLI command above)
[ ] Complete all Section 3 prerequisite checks
[ ] Audit all installed extensions for compatibility with target version
[ ] Decide on minor version upgrade strategy (automatic vs manual)
[ ] Identify your major version upgrade path — verify direct jump is supported
[ ] Choose your upgrade approach (see Section 7) and read its limitations
[ ] Take a manual RDS snapshot before any upgrade begins
[ ] Restore the snapshot to a test instance
[ ] Run your full upgrade process against the test instance first
[ ] Run your application test suite against the upgraded test instance
[ ] Validate query performance on the test instance — compare against baseline
[ ] Confirm all extensions work correctly on the test instance
[ ] Update parameter groups for the target version if required
[ ] Document your rollback plan
[ ] Schedule the upgrade during a maintenance window
[ ] Notify stakeholders in advance
[ ] Have a team member on standby during the upgrade
```

---

## Section 6 — Minor Version Upgrades

Minor version upgrades (e.g., 16.6 → 16.7) include security patches and bug fixes. They carry low risk and should be applied regularly.

**On RDS — Automatic (recommended for most teams):**

📄 Script: [scripts/bash/05-enable-auto-minor-upgrade.sh](scripts/bash/05-enable-auto-minor-upgrade.sh)

```bash
# Enable automatic minor version upgrade
aws rds modify-db-instance \
  --db-instance-identifier your-db-name \
  --auto-minor-version-upgrade \
  --apply-immediately
```

AWS applies the patch during your scheduled maintenance window. If no maintenance window is set, configure one that aligns with your lowest-traffic period.

**On RDS — Manual:**

📄 Script: [scripts/bash/06-manual-minor-upgrade.sh](scripts/bash/06-manual-minor-upgrade.sh)

```bash
# Apply a specific minor version manually
aws rds modify-db-instance \
  --db-instance-identifier your-db-name \
  --engine-version 16.7 \
  --apply-immediately
```

> For Aurora, the AMVU setting applies at the cluster level. Check the Aurora release calendar for minor version availability before planning.

---

## Section 7 — Major Version Upgrades

Major version upgrades require more planning. Choose the approach that fits your downtime tolerance, team capability, and environment.

---

#### Approach A — RDS Snapshot Restore

**Best for:** Teams that want a safe fallback with minimal tooling complexity.
**Downtime:** Required — application must stop writes during upgrade.
**Risk:** Low — original snapshot always available to restore.

📄 Script: [scripts/bash/07-snapshot-restore-upgrade.sh](scripts/bash/07-snapshot-restore-upgrade.sh)

```bash
# 1. Take a manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier your-db-name \
  --db-snapshot-identifier pre-upgrade-snapshot-$(date +%Y%m%d)

# 2. Restore to a new instance on the target version
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier your-db-name-upgraded \
  --db-snapshot-identifier pre-upgrade-snapshot-YYYYMMDD \
  --engine-version 17.2

# 3. Validate — run tests against the restored instance
# 4. Update application connection string to point to the new instance
# 5. Decommission old instance after validation
```

---

#### Approach B — In-Place Upgrade (RDS)

**Best for:** Simpler environments where maintenance window downtime is acceptable.
**Downtime:** Required — instance unavailable during upgrade.
**Risk:** Medium — rollback requires restoring a pre-upgrade snapshot.

📄 Script: [scripts/bash/08-inplace-upgrade.sh](scripts/bash/08-inplace-upgrade.sh)

```bash
# Always take a manual snapshot first
aws rds create-db-snapshot \
  --db-instance-identifier your-db-name \
  --db-snapshot-identifier pre-upgrade-$(date +%Y%m%d)

# Modify the instance to the target major version
aws rds modify-db-instance \
  --db-instance-identifier your-db-name \
  --engine-version 17.2 \
  --allow-major-version-upgrade \
  --apply-immediately
```

👉 Full RDS major version upgrade process:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html

👉 Full Aurora major version upgrade process:
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html

---

#### Approach C — Logical Replication

**Best for:** Teams that need near-zero downtime without AWS-managed tooling.
**Downtime:** Minutes only (final cutover).
**Risk:** Higher complexity — requires careful setup, monitoring, and validation.

High-level steps:
1. Spin up a new RDS instance on the target version
2. Set up logical replication from the old instance to the new instance
3. Monitor replication lag until it is near zero
4. Stop writes to the old instance briefly
5. Wait for replication to fully drain
6. Switch application connection strings to the new instance
7. Decommission the old instance

👉 PostgreSQL logical replication documentation:
https://www.postgresql.org/docs/current/logical-replication.html

---

#### Approach D — AWS DMS Homogeneous Data Migration

**Best for:** Cross-account, cross-region migrations, or moving from self-managed PostgreSQL to RDS/Aurora with near-zero downtime.
**Downtime:** Near-zero when using Full Load + CDC.
**Risk:** Requires DMS setup, monitoring, and validation throughout the migration.

Use the **Homogeneous Data Migration** method in DMS for PostgreSQL-to-PostgreSQL migrations. This uses native PostgreSQL tools (`pg_dump` and `pg_restore`) under the hood, is fully serverless, and migrates tables, indexes, functions, stored procedures, triggers, and other database objects.

**Supported migration types:**
- Full load only
- Full load + CDC — recommended for near-zero downtime
- CDC only — when the target already has the schema in place

```bash
# High-level DMS Homogeneous Data Migration steps
# 1. Create source data provider (your source PostgreSQL instance)
# 2. Create target data provider (your new RDS/Aurora PostgreSQL instance)
# 3. Create a migration project connecting source and target
# 4. Choose Full Load + CDC migration type
# 5. Start the migration and monitor progress in the DMS console
# 6. Perform cutover when CDC lag reaches zero
```

> **Note:** Always verify that your source PostgreSQL version is supported by
> DMS Homogeneous Data Migration before planning. Check the latest supported
> source versions in the AWS DMS documentation as support expands over time.

👉 DMS Homogeneous Data Migration — PostgreSQL source:
https://docs.aws.amazon.com/dms/latest/userguide/dm-migrating-data-postgresql.html

👉 AWS blog — DMS homogeneous migration from PostgreSQL to Aurora PostgreSQL:
https://aws.amazon.com/blogs/database/aws-dms-homogeneous-data-migration-from-postgresql-to-amazon-aurora-postgresql/

---

#### Approach E — RDS Blue/Green Deployment

**Best for:** AWS-native near-zero downtime upgrades with built-in validation, easy rollback, and minimal operational complexity.
**Downtime:** Minutes only (switchover) — typically under one minute.
**Risk:** Low for most workloads — review limitations below before committing.

Blue/Green deployments use **logical replication** for major version upgrades and **physical replication** for minor version upgrades. AWS manages the staging environment, replication, and switchover automatically.

📄 Script: [scripts/bash/09-blue-green-upgrade.sh](scripts/bash/09-blue-green-upgrade.sh)

```bash
# 1. Create a Blue/Green deployment targeting the new major version
aws rds create-blue-green-deployment \
  --blue-green-deployment-name my-pg-upgrade \
  --source your-db-name \
  --target-engine-version 17.2 \
  --target-db-parameter-group-name your-pg17-param-group

# 2. Monitor deployment and replication lag
aws rds describe-blue-green-deployments \
  --filters Name=blue-green-deployment-name,Values=my-pg-upgrade

# 3. Validate the green environment thoroughly before switchover
# 4. Switchover — if lag is not zero by the timeout, rolls back automatically
aws rds switchover-blue-green-deployment \
  --blue-green-deployment-identifier <id> \
  --switchover-timeout 300
```

**Switchover best practices:**
- Validate the green environment fully before triggering switchover — run your test suite and check query performance
- Set a realistic `--switchover-timeout` — if replication lag is not drained by the timeout, the switchover rolls back with no impact to production
- Monitor replication lag before initiating — only switchover when lag is near zero
- Use Amazon RDS Proxy or Aurora smart drivers to minimise connection disruption during switchover
- Run post-upgrade steps (ANALYZE, extension updates, index validation) on the green environment *before* switchover where possible

**Key limitations for major version upgrades:**
- Uses logical replication — tables without a primary key or replica identity may not replicate correctly; audit your schema beforehand
- Unlogged tables are not replicated by default — set `rds.logically_replicate_unlogged_tables = 1` on the blue instance if needed; do not change this setting after the deployment is created
- High write throughput workloads may cause replication lag on the green environment — test under realistic load before switchover; for very high write throughput, consider DMS instead
- Delayed replication is not compatible with Blue/Green deployments for major version upgrades
- Zero-ETL integrations with Amazon Redshift must be deleted before switchover and recreated after
- AWS Secrets Manager managed master user passwords are not supported
- Blue and green environments must be in the same AWS account
- Cannot change encryption status during a Blue/Green deployment
- Auto Scaling policies on the blue environment are not copied to green — reconfigure after switchover
- Cannot change a blue DB cluster to a higher engine version than its corresponding green DB cluster

👉 RDS Blue/Green Deployments overview:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments-overview.html

👉 RDS Blue/Green Deployments limitations and considerations:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments-considerations.html

👉 Aurora Blue/Green Deployments limitations and considerations:
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html

👉 AWS blog — Blue/Green deployment for Aurora and RDS PostgreSQL:
https://aws.amazon.com/blogs/database/new-fully-managed-blue-green-deployment-in-amazon-aurora-postgresql-and-amazon-rds-for-postgresql/

---

## Section 8 — After the Upgrade

### 1. Verify the upgrade was successful

📄 Script: [scripts/sql/06-post-upgrade-verify.sql](scripts/sql/06-post-upgrade-verify.sql)

```sql
SELECT version();
SELECT current_setting('server_version_num');
```

### 2. Rebuild statistics

The query planner relies on statistics. After a major upgrade, rebuild them immediately to ensure optimal query plans. Without current statistics, the planner may choose inefficient execution paths.

📄 Script: [scripts/sql/07-post-upgrade-analyze.sql](scripts/sql/07-post-upgrade-analyze.sql)

```sql
-- Rebuild planner statistics for all tables
ANALYZE VERBOSE;

-- ANALYZE a specific table (useful for large databases)
ANALYZE VERBOSE your_schema.your_table_name;
```

### 3. Check for invalid indexes

📄 Script: [scripts/sql/08-post-upgrade-invalid-indexes.sql](scripts/sql/08-post-upgrade-invalid-indexes.sql)

```sql
-- Find invalid indexes
SELECT schemaname, relname, indexrelname
FROM pg_stat_user_indexes
JOIN pg_index ON pg_index.indexrelid = pg_stat_user_indexes.indexrelid
WHERE pg_index.indisvalid = false;

-- Rebuild a specific index
REINDEX INDEX your_index_name;

-- Rebuild all indexes on a table
REINDEX TABLE your_table_name;
```

### 4. Check extensions and take required action

Extensions are not automatically upgraded when you upgrade the engine. Audit and update them after every major version upgrade.

📄 Script: [scripts/sql/09-post-upgrade-extensions.sql](scripts/sql/09-post-upgrade-extensions.sql)

```sql
-- Check installed vs available extension versions
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE installed_version IS NOT NULL
ORDER BY name;

-- Update a specific extension
ALTER EXTENSION extension_name UPDATE;

-- Generate UPDATE statements for all extensions that are behind
SELECT 'ALTER EXTENSION ' || name || ' UPDATE;'
FROM pg_available_extensions
WHERE installed_version IS NOT NULL
  AND installed_version <> default_version;
```

**Extension-specific actions after upgrade:**

| Extension | Action required |
|-----------|----------------|
| **PostGIS** | Follow the full PostGIS upgrade sequence — may require additional topology and raster steps |
| **pg_repack** | `DROP EXTENSION pg_repack;` then `CREATE EXTENSION pg_repack;` |
| **pgvector** | `ALTER EXTENSION vector UPDATE;` — verify index behaviour post-update |
| **pg_stat_statements** | `ALTER EXTENSION pg_stat_statements UPDATE;` then reset stats for a clean baseline |
| **TimescaleDB** | Follow the Timescale version-specific upgrade guide — do not use `ALTER EXTENSION UPDATE` alone |

👉 RDS extension upgrade guide:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html

👉 Aurora extension upgrade guide:
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.Upgrading.ExtensionUpgrades.html

### 5. Monitor query performance

Check query performance in the days following the upgrade. The planner may produce different execution plans due to updated statistics, planner improvements, or changed parameter defaults. Compare against your pre-upgrade baseline.

**Option A — pg_stat_statements**

📄 Script: [scripts/sql/10-post-upgrade-query-perf.sql](scripts/sql/10-post-upgrade-query-perf.sql)

```sql
-- Reset to get a clean post-upgrade baseline
SELECT pg_stat_statements_reset();

-- After a few hours, check slowest queries by mean execution time
SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

**Option B — Amazon CloudWatch Database Insights (recommended for RDS/Aurora)**

For teams running multiple RDS or Aurora PostgreSQL instances, use **Amazon CloudWatch Database Insights** to monitor query performance across your entire database fleet from a single dashboard — without querying each instance individually.

Introduced in December 2024, Database Insights supports RDS and Aurora PostgreSQL and provides:

- Fleet-wide performance health dashboard — spot slow instances at a glance
- Slow query identification across all instances simultaneously
- SQL execution plan analysis (Advanced mode)
- Lock analysis and query statistics
- Integration with CloudWatch metrics and events

> AWS recommends upgrading to the Advanced mode of Database Insights before
> June 30, 2026, to retain access to execution plans and on-demand analysis.
> After that date, only Advanced mode will support these features.

👉 CloudWatch Database Insights documentation:
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html

👉 Configuring slow query monitoring for Aurora PostgreSQL with Database Insights:
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_DatabaseInsights.SlowSQL.html

👉 AWS blog — Database Insights applied in real-world scenarios:
https://aws.amazon.com/blogs/database/amazon-cloudwatch-database-insights-applied-in-real-scenarios/

---

## Section 9 — Stay Ahead

Paste this into your team wiki or runbook after every upgrade:

```
Last upgrade completed    : [date]
Current production version: [fill in]
Next community EOL date   : [check AWS release calendar]
RDS standard support ends : [check AWS release calendar]
Target upgrade version    : [fill in]
Upgrade owner             : [fill in]
Next upgrade review date  : [6 months from today]
Minor version strategy    : Automatic / Manual
Maintenance window        : [day and time]
```

Set a calendar reminder every 6 months to review the AWS release calendar and confirm you are on a supported version with enough runway to plan your next upgrade before EOL pressure forces a rushed migration.

---

## Quick Reference Commands

📄 Script: [scripts/sql/11-quick-reference.sql](scripts/sql/11-quick-reference.sql)

```sql
-- Version check
SELECT version();

-- Installed extensions vs available versions
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE installed_version IS NOT NULL ORDER BY name;

-- Invalid indexes
SELECT schemaname, relname, indexrelname
FROM pg_stat_user_indexes
JOIN pg_index ON pg_index.indexrelid = pg_stat_user_indexes.indexrelid
WHERE pg_index.indisvalid = false;

-- Open prepared transactions (must be zero before major upgrade)
SELECT count(*) FROM pg_catalog.pg_prepared_xacts;

-- Active replication slots (must be cleared before major upgrade)
SELECT * FROM pg_replication_slots WHERE slot_type NOT LIKE 'physical';

-- Rebuild statistics after upgrade
ANALYZE VERBOSE;

-- Update an extension
ALTER EXTENSION extension_name UPDATE;

-- Check database sizes
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database ORDER BY pg_database_size(datname) DESC;
```

---

## Key AWS Documentation References

| Topic | Link |
|-------|------|
| RDS PostgreSQL release calendar | https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html |
| Aurora PostgreSQL release calendar | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html |
| RDS major version upgrade process | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html |
| Aurora major version upgrade process | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html |
| RDS Blue/Green limitations | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments-considerations.html |
| Aurora Blue/Green limitations | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html |
| DMS Homogeneous Migration (PostgreSQL) | https://docs.aws.amazon.com/dms/latest/userguide/dm-migrating-data-postgresql.html |
| RDS extension versions | https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-extensions.html |
| Aurora extension versions | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html |
| CloudWatch Database Insights | https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html |
| Troubleshoot upgrade issues | https://repost.aws/knowledge-center/rds-postgresql-version-upgrade-issues |

*PostgreSQL community EOL dates: https://www.postgresql.org/support/versioning/*
