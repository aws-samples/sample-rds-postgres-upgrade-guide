# RDS PostgreSQL Upgrade Defense Strategy

A practical, step-by-step guide for planning and executing PostgreSQL major version upgrades on Amazon RDS and Aurora PostgreSQL — from pre-flight checks through post-upgrade validation.

Based on the 2026 talk: **"Is Your Database Keeping Up?"** presented at PostgreSQL Conference San Jose.

---

## What's Inside

This guide walks you through the full upgrade lifecycle:

| Section | What It Covers |
|---------|---------------|
| **1 — Know Where You Stand** | Version discovery across all environments using SQL and AWS CLI |
| **2 — Understand Your EOL Risk** | How to check community EOL, RDS standard support, and Extended Support dates |
| **2.5 — Prerequisites Check** | Pre-upgrade validation: instance classes, invalid databases, unsupported data types, disk space, replication slots |
| **3 — Check Your Extensions** | Extension audit and compatibility matrix (PostGIS, pgvector, pg_repack, pg_cron, TimescaleDB, and more) |
| **4 — Plan Your Upgrade Strategy** | Minor version strategy, major version upgrade paths, and a full pre-upgrade checklist |
| **5 — The Upgrade** | Five upgrade approaches with CLI examples and trade-offs |
| **6 — After the Upgrade** | Post-upgrade validation: statistics rebuild, index checks, extension updates, query performance monitoring |
| **7 — Stay Ahead** | Maintenance tracking template and 6-month review cadence |

## Upgrade Approaches Covered

| Approach | Downtime | Complexity | Best For |
|----------|----------|------------|----------|
| **Snapshot Restore** | Yes | Low | Safe fallback with minimal tooling |
| **In-Place Upgrade** | Yes | Low | Simple environments with maintenance windows |
| **Logical Replication** | Minutes | High | Near-zero downtime without managed tooling |
| **AWS DMS Homogeneous Migration** | Near-zero | Medium | Cross-account, cross-region, or self-managed to RDS/Aurora |
| **Blue/Green Deployment** | Minutes | Low | AWS-native near-zero downtime with built-in rollback |

## Quick Start

```sql
-- Step 1: Know where you stand
SELECT version();
```

```bash
# Step 2: Check all your RDS instances
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,EngineVersion,DBInstanceStatus]' \
  --output table
```

```bash
# Step 3: Check valid upgrade targets for your version
aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version <your-current-version> \
  --query 'DBEngineVersions[*].ValidUpgradeTarget[*].{Version:EngineVersion,MajorUpgrade:IsMajorVersionUpgrade}' \
  --output table
```

Then work through the [full guide](postgres-upgrade-guide-1.md).

## Key AWS Documentation

- [RDS PostgreSQL Release Calendar](https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html)
- [Aurora PostgreSQL Release Calendar](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html)
- [RDS Major Version Upgrade Process](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process.html)
- [Aurora Major Version Upgrade Process](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html)
- [RDS Blue/Green Deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments-overview.html)
- [DMS Homogeneous Migration (PostgreSQL)](https://docs.aws.amazon.com/dms/latest/userguide/dm-migrating-data-postgresql.html)
- [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html)

## License

This project is licensed under the MIT License.
