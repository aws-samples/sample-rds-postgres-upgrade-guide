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
| **3 — Prerequisites Check** | Pre-upgrade validation: instance classes, invalid databases, unsupported data types, disk space, replication slots |
| **4 — Check Your Extensions** | Extension audit and compatibility matrix (PostGIS, pgvector, pg_repack, pg_cron, and more) |
| **5 — Plan Your Upgrade Strategy** | Minor version strategy, major version upgrade paths, and a full pre-upgrade checklist |
| **6 — Minor Version Upgrades** | Automatic and manual minor version upgrade steps |
| **7 — Major Version Upgrades** | Five upgrade approaches with CLI examples and trade-offs |
| **8 — After the Upgrade** | Post-upgrade validation: statistics rebuild, index checks, extension updates, query performance monitoring |
| **9 — Stay Ahead** | Maintenance tracking template and 6-month review cadence |

## Upgrade Approaches Covered

| Approach | Downtime | Complexity | Best For |
|----------|----------|------------|----------|
| **Snapshot Restore** | Yes | Low | Safe fallback with minimal tooling |
| **In-Place Upgrade** | Yes | Low | Simple environments with maintenance windows |
| **Logical Replication** | Minutes | High | Near-zero downtime without managed tooling |
| **AWS DMS Homogeneous Migration** | Near-zero | Medium | Cross-account, cross-region, or self-managed to RDS/Aurora |
| **Blue/Green Deployment** | Minutes | Low | AWS-native near-zero downtime with built-in rollback |

## Runnable Scripts

This repo includes ready-to-use scripts extracted from the guide. Clone the repo and run them directly.

### SQL Scripts (`scripts/sql/`)

| Script | Purpose |
|--------|---------|
| `01-check-version.sql` | Check PostgreSQL version |
| `02-prereq-invalid-databases.sql` | Check for invalid databases, prepared transactions, replication slots |
| `03-prereq-unsupported-datatypes.sql` | Find unsupported reg* data types |
| `04-prereq-disk-space.sql` | Check database sizes and free space |
| `05-check-extensions.sql` | List all installed extensions |
| `06-post-upgrade-verify.sql` | Verify upgrade was successful |
| `07-post-upgrade-analyze.sql` | Rebuild planner statistics |
| `08-post-upgrade-invalid-indexes.sql` | Find and rebuild invalid indexes |
| `09-post-upgrade-extensions.sql` | Check and update extensions |
| `10-post-upgrade-query-perf.sql` | Monitor query performance via pg_stat_statements |
| `11-quick-reference.sql` | All key queries in one file |

### Bash Scripts (`scripts/bash/`)

| Script | Purpose |
|--------|---------|
| `01-check-rds-instances.sh` | List all RDS instances with versions |
| `02-check-multi-env.sh` | Check versions across multiple environments |
| `03-check-upgrade-targets.sh` | Show valid upgrade targets for a version |
| `04-list-available-versions.sh` | List all available RDS PostgreSQL versions |
| `05-enable-auto-minor-upgrade.sh` | Enable automatic minor version upgrades |
| `06-manual-minor-upgrade.sh` | Apply a specific minor version |
| `07-snapshot-restore-upgrade.sh` | Major upgrade via snapshot restore |
| `08-inplace-upgrade.sh` | Major upgrade via in-place modify |
| `09-blue-green-upgrade.sh` | Major upgrade via Blue/Green deployment |

## Quick Start

```sql
-- Step 1: Know where you stand
SELECT version();
```

```bash
# Step 2: Check all your RDS instances
./scripts/bash/01-check-rds-instances.sh

# Step 3: Check valid upgrade targets for your version
./scripts/bash/03-check-upgrade-targets.sh 14.9
```

Then work through the [full guide](postgres-upgrade-guide.md).

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
