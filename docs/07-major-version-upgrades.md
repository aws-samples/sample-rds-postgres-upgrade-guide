# Section 7 — Major Version Upgrades

[← Previous: Minor Version Upgrades](06-minor-version-upgrades.md) | [Back to README](../README.md) | [Next: After the Upgrade →](08-after-the-upgrade.md)

---

Major version upgrades require more planning. Choose the approach that fits your downtime tolerance, team capability, and environment.

Before proceeding, ensure you have completed the [prerequisites check](03-prerequisites.md) and [extension audit](04-extensions.md).

---

### Approach A — RDS Snapshot Restore

**Best for:** Teams that want a safe fallback with minimal tooling complexity.
**Downtime:** Required — application must stop writes during upgrade.
**Risk:** Low — original snapshot always available to restore.

📄 Script: [scripts/bash/07-snapshot-restore-upgrade.sh](../scripts/bash/07-snapshot-restore-upgrade.sh)

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

### Approach B — In-Place Upgrade (RDS)

**Best for:** Simpler environments where maintenance window downtime is acceptable.
**Downtime:** Required — instance unavailable during upgrade.
**Risk:** Medium — rollback requires restoring a pre-upgrade snapshot.

📄 Script: [scripts/bash/08-inplace-upgrade.sh](../scripts/bash/08-inplace-upgrade.sh)

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

### Approach C — Logical Replication

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

### Approach D — AWS DMS Homogeneous Data Migration

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
https://docs.aws.amazon.com/dms/latest/userguide/data-migrations.html

👉 AWS blog — DMS homogeneous migration from PostgreSQL to Aurora PostgreSQL:
https://aws.amazon.com/blogs/database/aws-dms-homogeneous-data-migration-from-postgresql-to-amazon-aurora-postgresql/

---

### Approach E — RDS Blue/Green Deployment

**Best for:** AWS-native near-zero downtime upgrades with built-in validation, easy rollback, and minimal operational complexity.
**Downtime:** Minutes only (switchover) — typically under one minute.
**Risk:** Low for most workloads — review limitations below before committing.

Blue/Green deployments use **logical replication** for major version upgrades and **physical replication** for minor version upgrades. AWS manages the staging environment, replication, and switchover automatically.

📄 Script: [scripts/bash/09-blue-green-upgrade.sh](../scripts/bash/09-blue-green-upgrade.sh)

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

After completing any major version upgrade, proceed to [Section 8 — After the Upgrade](08-after-the-upgrade.md).

---

[← Previous: Minor Version Upgrades](06-minor-version-upgrades.md) | [Back to README](../README.md) | [Next: After the Upgrade →](08-after-the-upgrade.md)
