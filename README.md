# RDS PostgreSQL Upgrade Defense Strategy

A practical, step-by-step guide for planning and executing PostgreSQL major version upgrades on Amazon RDS and Aurora PostgreSQL — from pre-flight checks through post-upgrade validation.

Based on the 2026 talk: **"RDS Maintenance: Strategies for Patching and Version Upgrades"** presented at PostgreSQL Conference San Jose 2026.

---

## Guide Sections

Start here → run `SELECT version();` across every environment, then work through the sections below.

| # | Section | What It Covers |
|---|---------|---------------|
| 1 | [Know Where You Stand](docs/01-know-where-you-stand.md) | Version discovery across all environments using SQL and AWS CLI |
| 2 | [Understand Your EOL Risk](docs/02-eol-risk.md) | How to check community EOL, RDS standard support, and Extended Support dates |
| 3 | [Prerequisites Check](docs/03-prerequisites.md) | Pre-upgrade validation: instance classes, invalid databases, unsupported data types, disk space, database objects, large objects |
| 4 | [Check Your Extensions](docs/04-extensions.md) | Extension audit and compatibility matrix (PostGIS, pgvector, pg_repack, pg_cron, and more) |
| 5 | [Plan Your Upgrade Strategy](docs/05-plan-upgrade-strategy.md) | OS updates, minor version strategy, major version upgrade paths, and pre-upgrade checklist |
| 6 | [Minor Version Upgrades](docs/06-minor-version-upgrades.md) | Automatic and manual minor version upgrade steps |
| 7 | [Major Version Upgrades](docs/07-major-version-upgrades.md) | Five upgrade approaches with CLI examples and trade-offs |
| 8 | [After the Upgrade](docs/08-after-the-upgrade.md) | Post-upgrade validation: statistics rebuild, index checks, extension updates, query performance monitoring |
| 9 | [Stay Ahead](docs/09-stay-ahead.md) | Maintenance tracking template and 6-month review cadence |
| — | [Quick Reference](docs/10-quick-reference.md) | All key commands and AWS documentation links in one page |

## Upgrade Approaches Covered

| Approach | Downtime | Complexity | Best For |
|----------|----------|------------|----------|
| **Snapshot Restore** | Yes | Low | Safe fallback with minimal tooling |
| **In-Place Upgrade** | Yes | Low | Simple environments with maintenance windows |
| **Logical Replication** | Minutes | High | Near-zero downtime without managed tooling |
| **AWS DMS Homogeneous Migration** | Near-zero | Medium | Cross-account, cross-region, or self-managed to RDS/Aurora |
| **Blue/Green Deployment** | Minutes | Low | AWS-native near-zero downtime with built-in rollback |

## Runnable Scripts

This repo includes scripts extracted from the guide. Clone the repo and review them — update placeholder values (instance names, versions, connection strings) for your environment before running.

> **⚠️ Important:** Several scripts contain placeholder connection strings and instance identifiers. Always review each script and replace example values with your own before executing. Scripts that modify RDS instances include a `WARNING` comment at the top — read it before running.

### SQL Scripts ([`scripts/sql/`](scripts/sql/))

| Script | Purpose |
|--------|---------|
| [`01-check-version.sql`](scripts/sql/01-check-version.sql) | Check PostgreSQL version |
| [`02-prereq-invalid-databases.sql`](scripts/sql/02-prereq-invalid-databases.sql) | Check for invalid databases, prepared transactions, replication slots |
| [`03-prereq-unsupported-datatypes.sql`](scripts/sql/03-prereq-unsupported-datatypes.sql) | Find unsupported reg* data types |
| [`04-prereq-disk-space.sql`](scripts/sql/04-prereq-disk-space.sql) | Check database sizes and free space |
| [`05-check-extensions.sql`](scripts/sql/05-check-extensions.sql) | List all installed extensions |
| [`06-post-upgrade-verify.sql`](scripts/sql/06-post-upgrade-verify.sql) | Verify upgrade was successful |
| [`07-post-upgrade-analyze.sql`](scripts/sql/07-post-upgrade-analyze.sql) | Rebuild planner statistics |
| [`08-post-upgrade-invalid-indexes.sql`](scripts/sql/08-post-upgrade-invalid-indexes.sql) | Find and rebuild invalid indexes |
| [`09-post-upgrade-extensions.sql`](scripts/sql/09-post-upgrade-extensions.sql) | Check and update extensions |
| [`10-post-upgrade-query-perf.sql`](scripts/sql/10-post-upgrade-query-perf.sql) | Monitor query performance via pg_stat_statements |
| [`11-quick-reference.sql`](scripts/sql/11-quick-reference.sql) | All key queries in one file |
| [`12-check-database-objects.sql`](scripts/sql/12-check-database-objects.sql) | Count database objects to estimate upgrade duration |

### Bash Scripts ([`scripts/bash/`](scripts/bash/))

| Script | Purpose |
|--------|---------|
| [`01-check-rds-instances.sh`](scripts/bash/01-check-rds-instances.sh) | List all RDS instances with versions |
| [`02-check-multi-env.sh`](scripts/bash/02-check-multi-env.sh) | Check versions across multiple environments |
| [`03-check-upgrade-targets.sh`](scripts/bash/03-check-upgrade-targets.sh) | Show valid upgrade targets for a version |
| [`04-list-available-versions.sh`](scripts/bash/04-list-available-versions.sh) | List all available RDS PostgreSQL versions |
| [`05-enable-auto-minor-upgrade.sh`](scripts/bash/05-enable-auto-minor-upgrade.sh) | Enable automatic minor version upgrades |
| [`06-manual-minor-upgrade.sh`](scripts/bash/06-manual-minor-upgrade.sh) | Apply a specific minor version |
| [`07-snapshot-restore-upgrade.sh`](scripts/bash/07-snapshot-restore-upgrade.sh) | Major upgrade via snapshot restore |
| [`08-inplace-upgrade.sh`](scripts/bash/08-inplace-upgrade.sh) | Major upgrade via in-place modify |
| [`09-blue-green-upgrade.sh`](scripts/bash/09-blue-green-upgrade.sh) | Major upgrade via Blue/Green deployment |

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

Then start with [Section 1 — Know Where You Stand](docs/01-know-where-you-stand.md).

## License

This project is licensed under the [MIT-0 License](LICENSE).
