#!/bin/bash
# Section 7 — Approach B: In-Place Upgrade (RDS)
# Usage: ./08-inplace-upgrade.sh <db-instance-identifier> <target-version>
# Example: ./08-inplace-upgrade.sh my-db 17.2

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <db-instance-identifier> <target-version>"
  echo "Example: $0 my-db 17.2"
  exit 1
fi

DB_ID="$1"
TARGET_VERSION="$2"
SNAPSHOT_ID="pre-upgrade-$(date +%Y%m%d)"

echo "=== Step 1: Taking manual snapshot first ==="
aws rds create-db-snapshot \
  --db-instance-identifier "$DB_ID" \
  --db-snapshot-identifier "$SNAPSHOT_ID"

echo ""
echo "Waiting for snapshot to complete..."
aws rds wait db-snapshot-available --db-snapshot-identifier "$SNAPSHOT_ID"

echo ""
echo "=== Step 2: Modifying instance to target major version ==="
aws rds modify-db-instance \
  --db-instance-identifier "$DB_ID" \
  --engine-version "$TARGET_VERSION" \
  --allow-major-version-upgrade \
  --apply-immediately

echo ""
echo "In-place upgrade initiated for $DB_ID to version $TARGET_VERSION"
echo "Pre-upgrade snapshot: $SNAPSHOT_ID"
