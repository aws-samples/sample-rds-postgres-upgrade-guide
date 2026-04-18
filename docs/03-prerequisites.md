# Section 3 — Prerequisites Check Before You Upgrade

[← Previous: EOL Risk](02-eol-risk.md) | [Back to README](../README.md) | [Next: Check Your Extensions →](04-extensions.md)

---

Before planning your upgrade path, run through these prerequisite checks. Skipping these is the most common reason upgrades fail or roll back mid-process.

### 1. Unsupported DB instance classes for the target version

Some older instance types are not supported on newer PostgreSQL major versions. Verify your instance class is compatible with your target version before starting.

📄 Script: [scripts/bash/03-check-upgrade-targets.sh](../scripts/bash/03-check-upgrade-targets.sh)

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

📄 Script: [scripts/sql/02-prereq-invalid-databases.sql](../scripts/sql/02-prereq-invalid-databases.sql)

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

📄 Script: [scripts/sql/03-prereq-unsupported-datatypes.sql](../scripts/sql/03-prereq-unsupported-datatypes.sql)

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

### 4. Disk space and database size

Knowing your database sizes helps estimate backup and snapshot time during the upgrade process. While AWS manages storage for RDS instances, the pre-upgrade snapshot duration is influenced by incremental changes and overall database size. For upgrade approaches that involve snapshot restore or DMS, database size directly affects migration time.

📄 Script: [scripts/sql/04-prereq-disk-space.sql](../scripts/sql/04-prereq-disk-space.sql)

```sql
-- Check current database sizes
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Check total size of the current database
SELECT pg_size_pretty(pg_database_size(current_database())) AS total_size;
```

### 5. Database object count

Major version upgrade duration for the `pg_upgrade` step is primarily driven by the number of databases and database objects (tables, indexes, views, functions, partitions, etc.) — not the overall database size. A small database with thousands of partitions and indexes can take significantly longer to upgrade than a large database with fewer objects. Additionally, large objects (`pg_largeobject`) can significantly increase upgrade downtime — review and clean up orphaned large objects using the `vacuumlo` utility before upgrading. Audit your object count before scheduling your upgrade window.

> **Important:** Run these queries in every database on the instance, not just your primary application database. The upgrade process uses `pg_upgrade` across all databases, and the precheck procedure checks all potential incompatible conditions across all databases in the instance. The total object count across all of them affects the overall upgrade duration.

👉 Estimating upgrade downtime: https://repost.aws/knowledge-center/rds-postgresql-upgrade-downtime

📄 Script: [scripts/sql/12-check-database-objects.sql](../scripts/sql/12-check-database-objects.sql)

```sql
-- Total object count across all types
SELECT count(*) AS total_objects FROM pg_class;

-- Object count by type
SELECT
  CASE relkind
    WHEN 'r' THEN 'table'
    WHEN 'i' THEN 'index'
    WHEN 'S' THEN 'sequence'
    WHEN 'v' THEN 'view'
    WHEN 'm' THEN 'materialized view'
    WHEN 'c' THEN 'composite type'
    WHEN 't' THEN 'TOAST table'
    WHEN 'f' THEN 'foreign table'
    WHEN 'p' THEN 'partitioned table'
    WHEN 'I' THEN 'partitioned index'
    ELSE relkind::text
  END AS object_type,
  count(*) AS count
FROM pg_class
GROUP BY relkind
ORDER BY count DESC;

-- Object count by schema (excluding system schemas)
SELECT n.nspname AS schema, count(*) AS object_count
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
GROUP BY n.nspname
ORDER BY object_count DESC;
```

> **Tip:** Run the object count query on a test instance and time a dry-run upgrade to estimate how long the production upgrade will take. This is more reliable than estimating based on database size alone.

To check for large objects that may increase upgrade downtime:

```sql
-- Count large objects
SELECT count(*) AS large_object_count FROM pg_largeobject_metadata;
```

If you have millions of large objects, consider cleaning up orphaned ones using the `vacuumlo` utility before upgrading. AWS recommends using an instance type with at least 32 GB of memory if your database contains 25 to 30 million large objects.

👉 Managing large objects with the lo module: https://www.postgresql.org/docs/current/lo.html
👉 vacuumlo utility: https://www.postgresql.org/docs/current/vacuumlo.html
👉 RDS major version upgrade — handling large objects: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html

### 6. Release dates between source and target version

Check that the target minor version is already available on RDS or Aurora before scheduling your upgrade. Not all community releases are immediately available on RDS.

📄 Script: [scripts/bash/04-list-available-versions.sh](../scripts/bash/04-list-available-versions.sh)

```bash
# List all available PostgreSQL versions on RDS
aws rds describe-db-engine-versions \
  --engine postgres \
  --query 'DBEngineVersions[*].EngineVersion' \
  --output table
```

👉 Minor version release calendar:
https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html

### 7. Learn about limitations and best practices for your chosen upgrade approach

Each upgrade approach has its own constraints. Before finalising your upgrade strategy, read the documentation for the method you have chosen (see [Section 7 — Major Version Upgrades](07-major-version-upgrades.md)) and factor these into your plan — especially around logical replication slots, Multi-AZ behaviour, read replicas, parameter group compatibility, and extension handling.

---

[← Previous: EOL Risk](02-eol-risk.md) | [Back to README](../README.md) | [Next: Check Your Extensions →](04-extensions.md)
