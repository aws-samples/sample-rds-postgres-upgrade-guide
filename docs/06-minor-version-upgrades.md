# Section 6 — Minor Version Upgrades

[← Previous: Plan Your Upgrade Strategy](05-plan-upgrade-strategy.md) | [Back to README](../README.md) | [Next: Major Version Upgrades →](07-major-version-upgrades.md)

---

Minor version upgrades (e.g., 16.6 → 16.7) include security patches and bug fixes. They carry low risk and should be applied regularly.

**On RDS — Automatic (recommended for most teams):**

📄 Script: [scripts/bash/05-enable-auto-minor-upgrade.sh](../scripts/bash/05-enable-auto-minor-upgrade.sh)

```bash
# Enable automatic minor version upgrade
aws rds modify-db-instance \
  --db-instance-identifier your-db-name \
  --auto-minor-version-upgrade \
  --apply-immediately
```

AWS applies the patch during your scheduled maintenance window. If no maintenance window is set, configure one that aligns with your lowest-traffic period.

**On RDS — Manual:**

📄 Script: [scripts/bash/06-manual-minor-upgrade.sh](../scripts/bash/06-manual-minor-upgrade.sh)

```bash
# Apply a specific minor version manually
aws rds modify-db-instance \
  --db-instance-identifier your-db-name \
  --engine-version 16.7 \
  --apply-immediately
```

> For Aurora, the AMVU setting applies at the cluster level. Check the Aurora release calendar for minor version availability before planning.

---

[← Previous: Plan Your Upgrade Strategy](05-plan-upgrade-strategy.md) | [Back to README](../README.md) | [Next: Major Version Upgrades →](07-major-version-upgrades.md)
