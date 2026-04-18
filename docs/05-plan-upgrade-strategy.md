# Section 5 — Plan Your Upgrade Strategy

[← Previous: Check Your Extensions](04-extensions.md) | [Back to README](../README.md) | [Next: Minor Version Upgrades →](06-minor-version-upgrades.md)

---

### Step 1 — OS Update Consideration

For RDS and Aurora, AWS manages the underlying operating system. Periodically, AWS provides OS updates for your DB instances that fall into two categories:

- **Mandatory OS updates** — required updates with an apply date. If you do not apply them before the deadline, AWS will automatically apply them during your next maintenance window after the specified date. These are typically related to security and instance reliability.
- **Optional OS updates** — available at any time with no deadline. AWS recommends applying these periodically to keep your RDS fleet up to date and maintain your security posture. RDS does not apply optional updates automatically.

OS updates typically take about 10 minutes and do not change the DB engine version or instance class. For Multi-AZ deployments, AWS applies OS updates to the standby first, promotes it, then patches the old primary — reducing downtime to a brief failover.

> **Tip:** To be notified when a new optional OS patch becomes available, subscribe to the `RDS-EVENT-0230` event in the security patching category.

You can check for pending OS updates using the console (Maintenance & backups tab) or the CLI:

```bash
# Check for pending maintenance actions on your instance
aws rds describe-pending-maintenance-actions \
  --resource-identifier arn:aws:rds:<region>:<account-id>:db:<db-instance-id>
```

A mandatory update will include `AutoAppliedAfterDate` and `CurrentApplyDate` values in the response. An optional update will not include these fields.

To apply a pending OS update immediately:

```bash
aws rds apply-pending-maintenance-action \
  --resource-identifier arn:aws:rds:<region>:<account-id>:db:<db-instance-id> \
  --apply-action system-update \
  --opt-in-type immediate
```

> **Important:** Staying current on all optional and mandatory OS updates may be required to meet various compliance obligations. AWS recommends applying all updates routinely during your maintenance windows.

For RDS and Aurora, OS updates and DB engine upgrades are separate processes. Although both can be scheduled within the same maintenance window, we recommend applying them separately. If performance issues arise after a combined update, it becomes difficult to determine whether the OS patch or the engine upgrade caused the problem. Apply the OS update first, validate, and then proceed with the engine upgrade in a subsequent window.

For self-managed PostgreSQL on EC2, plan OS updates separately from the database upgrade and never upgrade both at the same time in production.

👉 Upgrading a PostgreSQL DB instance: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html
👉 Maintaining a DB instance: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.Maintenance.html
👉 Operating system updates: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.Maintenance.html#OS_Updates

### Step 2 — Minor Version Strategy

Decide upfront how you will handle minor version upgrades:

- **Option A — Enable Automatic Minor Version Upgrade (AMVU)** on RDS: AWS applies minor patches during your maintenance window automatically. Best for teams who want hands-off security patching with minimal operational overhead.
- **Option B — Manual minor version upgrades**: You control when patches are applied. Best for teams with strict change management or compliance requirements. If you choose this, build it into your maintenance schedule — do not let minor versions drift.

> Check current minor version availability before planning:
> https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html

For detailed minor version upgrade commands, see [Section 6 — Minor Version Upgrades](06-minor-version-upgrades.md).

### Step 3 — Major Version Upgrade Path

RDS and Aurora support skipping major versions in some upgrade paths — sequential upgrades are not always required. However, not every version-to-version jump is supported as a direct upgrade, and the available paths depend on your current version.

**Always verify the exact upgrade targets available for your specific version:**

📄 Script: [scripts/bash/03-check-upgrade-targets.sh](../scripts/bash/03-check-upgrade-targets.sh)

```bash
# Check which versions you can upgrade to directly from your current version
aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version <your-current-version> \
  --query 'DBEngineVersions[*].ValidUpgradeTarget[*].{Version:EngineVersion,MajorUpgrade:IsMajorVersionUpgrade}' \
  --output table
```

If your target version is not available as a direct upgrade, an intermediate hop may be required. Test the full path in a non-production environment before scheduling production.

For major version upgrade approaches, see [Section 7 — Major Version Upgrades](07-major-version-upgrades.md).

### Pre-Upgrade Checklist

```
[ ] Run SELECT version() across all environments — document current versions
[ ] Check valid upgrade targets for your current version (CLI command above)
[ ] Complete all prerequisite checks (Section 3)
[ ] Audit all installed extensions for compatibility with target version (Section 4)
[ ] Decide on minor version upgrade strategy (automatic vs manual)
[ ] Identify your major version upgrade path — verify direct jump is supported
[ ] Choose your upgrade approach (Section 7) and read its limitations
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

[← Previous: Check Your Extensions](04-extensions.md) | [Back to README](../README.md) | [Next: Minor Version Upgrades →](06-minor-version-upgrades.md)
