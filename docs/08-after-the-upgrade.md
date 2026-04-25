# Section 8 — After the Upgrade

[← Previous: Major Version Upgrades](07-major-version-upgrades.md) | [Back to README](../README.md) | [Next: Stay Ahead →](09-stay-ahead.md)

---

### 1. Verify the upgrade was successful

📄 Script: [scripts/sql/06-post-upgrade-verify.sql](../scripts/sql/06-post-upgrade-verify.sql)

```sql
SELECT version();
SELECT current_setting('server_version_num');
```

### 2. Rebuild statistics

The query planner relies on statistics. After a major upgrade, rebuild them immediately to ensure optimal query plans. Without current statistics, the planner may choose inefficient execution paths.

> **PostgreSQL 18 and later:** pg_upgrade now preserves optimizer statistics during the upgrade, so a full `ANALYZE` is no longer required. However, extended statistics (created with `CREATE STATISTICS`) are not preserved and must be rebuilt. Use the following command to collect only the missing statistics:
>
> ```bash
> vacuumdb --all --analyze-only --missing-stats-only
> ```
>
> For versions prior to PostgreSQL 18, run a full `ANALYZE` as shown below.
>
> 👉 PostgreSQL 18 release notes — pg_upgrade retains optimizer statistics:
> https://www.postgresql.org/docs/release/18.0/

📄 Script: [scripts/sql/07-post-upgrade-analyze.sql](../scripts/sql/07-post-upgrade-analyze.sql)

```sql
-- Rebuild planner statistics for all tables
ANALYZE VERBOSE;

-- ANALYZE a specific table (useful for large databases)
ANALYZE VERBOSE your_schema.your_table_name;
```

### 3. Check for invalid indexes

📄 Script: [scripts/sql/08-post-upgrade-invalid-indexes.sql](../scripts/sql/08-post-upgrade-invalid-indexes.sql)

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

Extensions are not automatically upgraded when you upgrade the engine. Audit and update them after every major version upgrade. For pre-upgrade extension checks, see [Section 4 — Check Your Extensions](04-extensions.md).

📄 Script: [scripts/sql/09-post-upgrade-extensions.sql](../scripts/sql/09-post-upgrade-extensions.sql)

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
| **PostGIS** | Follow the full PostGIS upgrade sequence: run `SELECT postGIS_extensions_upgrade();` after the engine upgrade. If upgrading from PostGIS 2 to PostGIS 3, run the command twice — the first extracts raster into a separate `postgis_raster` extension, the second completes the upgrade. Verify all dependent extensions (`postgis_topology`, `postgis_raster`, `postgis_tiger_geocoder`) are updated. |
| **pg_repack** | `DROP EXTENSION pg_repack;` then `CREATE EXTENSION pg_repack;` |
| **pgvector** | `ALTER EXTENSION vector UPDATE;` — verify index behaviour post-update |
| **pg_stat_statements** | `ALTER EXTENSION pg_stat_statements UPDATE;` then reset stats for a clean baseline |

👉 RDS extension upgrade guide:
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html

👉 Aurora extension upgrade guide:
https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.Upgrading.ExtensionUpgrades.html

👉 Managing spatial data with PostGIS (includes upgrade steps):
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.PostGIS.html

👉 Troubleshoot PostGIS extension during RDS for PostgreSQL upgrade:
https://aws.amazon.com/premiumsupport/knowledge-center/rds-postgresql-upgrade-postgis/

### 5. Monitor query performance

Check query performance in the days following the upgrade. The planner may produce different execution plans due to updated statistics, planner improvements, or changed parameter defaults. Compare against your pre-upgrade baseline.

**Option A — pg_stat_statements**

📄 Script: [scripts/sql/10-post-upgrade-query-perf.sql](../scripts/sql/10-post-upgrade-query-perf.sql)

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

[← Previous: Major Version Upgrades](07-major-version-upgrades.md) | [Back to README](../README.md) | [Next: Stay Ahead →](09-stay-ahead.md)
