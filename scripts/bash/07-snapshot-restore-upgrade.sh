#!/bin/bash
# Section 7 — Approach A: RDS Snapshot Restore Upgrade
# WARNING: This script creates a snapshot and restores a new RDS instance. Review and test in a non-production environment first.
# Usage: ./07-snapshot-restore-upgrade.sh <db-instance-identifier> <target-version>
# Example: ./07-snapshot-restore-upgrade.sh my-db 17.2

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <db-instance-identifier> <target-version>"
  echo "Example: $0 my-db 17.2"
  exit 1
fi

DB_ID="$1"
TARGET_VERSION="$2"
SNAPSHOT_ID="pre-upgrade-snapshot-$(date +%Y%m%d)"

echo "=== Step 1: Taking manual snapshot ==="
aws rds create-db-snapshot \
  --db-instance-identifier "$DB_ID" \
  --db-snapshot-identifier "$SNAPSHOT_ID"

echo ""
echo "Waiting for snapshot to complete..."
aws rds wait db-snapshot-available --db-snapshot-identifier "$SNAPSHOT_ID"

echo ""
echo "=== Step 2: Restoring to new instance on target version ==="
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "${DB_ID}-upgraded" \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --engine-version "$TARGET_VERSION"

echo ""
echo "Restore initiated. New instance: ${DB_ID}-upgraded"
echo "Next steps:"
echo "  1. Wait for the new instance to become available"
echo "  2. Validate — run tests against the restored instance"
echo "  3. Update application connection string to point to the new instance"
echo "  4. Decommission old instance after validation"
