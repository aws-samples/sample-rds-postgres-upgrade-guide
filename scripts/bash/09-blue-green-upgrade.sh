#!/bin/bash
# Section 7 — Approach E: RDS Blue/Green Deployment
# WARNING: This script creates a Blue/Green deployment on your RDS instance. Review and test in a non-production environment first.
# Usage: ./09-blue-green-upgrade.sh <deployment-name> <db-instance-identifier> <target-version> <param-group-name>
# Example: ./09-blue-green-upgrade.sh my-pg-upgrade my-db 17.2 my-pg17-param-group

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
  echo "Usage: $0 <deployment-name> <db-instance-identifier> <target-version> <param-group-name>"
  echo "Example: $0 my-pg-upgrade my-db 17.2 my-pg17-param-group"
  exit 1
fi

DEPLOY_NAME="$1"
DB_ID="$2"
TARGET_VERSION="$3"
PARAM_GROUP="$4"

echo "=== Step 1: Creating Blue/Green deployment ==="
aws rds create-blue-green-deployment \
  --blue-green-deployment-name "$DEPLOY_NAME" \
  --source "$DB_ID" \
  --target-engine-version "$TARGET_VERSION" \
  --target-db-parameter-group-name "$PARAM_GROUP"

echo ""
echo "=== Step 2: Monitor deployment and replication lag ==="
echo "Run the following to check status:"
echo "  aws rds describe-blue-green-deployments --filters Name=blue-green-deployment-name,Values=$DEPLOY_NAME"
echo ""
echo "=== Step 3: When ready to switchover ==="
echo "  aws rds switchover-blue-green-deployment --blue-green-deployment-identifier <id> --switchover-timeout 300"
