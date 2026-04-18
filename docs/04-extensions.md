# Section 4 — Check Your Extensions

[← Previous: Prerequisites Check](03-prerequisites.md) | [Back to README](../README.md) | [Next: Plan Your Upgrade Strategy →](05-plan-upgrade-strategy.md)

---

Extensions are one of the most common causes of upgrade failures or post-upgrade issues. Always audit your extensions before upgrading.

### List all installed extensions

📄 Script: [scripts/sql/05-check-extensions.sql](../scripts/sql/05-check-extensions.sql)

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

> **Note:** For post-upgrade extension actions, see [Section 8 — After the Upgrade](08-after-the-upgrade.md).

---

[← Previous: Prerequisites Check](03-prerequisites.md) | [Back to README](../README.md) | [Next: Plan Your Upgrade Strategy →](05-plan-upgrade-strategy.md)
