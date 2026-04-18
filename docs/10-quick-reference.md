# Quick Reference Commands

[← Previous: Stay Ahead](09-stay-ahead.md) | [Back to README](../README.md)

---

📄 Script: [scripts/sql/11-quick-reference.sql](../scripts/sql/11-quick-reference.sql)

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

## Key AWS Documentation References

| Topic | Link |
|-------|------|
| RDS PostgreSQL release calendar | https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html |
| Aurora PostgreSQL release calendar | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html |
| RDS major version upgrade process | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html |
| Aurora major version upgrade process | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html |
| RDS Blue/Green limitations | https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments-considerations.html |
| Aurora Blue/Green limitations | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html |
| DMS Homogeneous Migration (PostgreSQL) | https://docs.aws.amazon.com/dms/latest/userguide/data-migrations.html |
| RDS extension versions | https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-extensions.html |
| Aurora extension versions | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html |
| CloudWatch Database Insights | https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html |
| Troubleshoot upgrade issues | https://repost.aws/knowledge-center/rds-postgresql-version-upgrade-issues |

*PostgreSQL community EOL dates: https://www.postgresql.org/support/versioning/*

---

[← Previous: Stay Ahead](09-stay-ahead.md) | [Back to README](../README.md)
