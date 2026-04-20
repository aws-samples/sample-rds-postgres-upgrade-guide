#!/bin/bash
# Section 7: Enable automatic minor version upgrade
# WARNING: This script modifies your RDS instance. Review and test in a non-production environment first.
# Usage: ./05-enable-auto-minor-upgrade.sh <db-instance-identifier>

if [ -z "$1" ]; then
  echo "Usage: $0 <db-instance-identifier>"
  exit 1
fi

aws rds modify-db-instance \
  --db-instance-identifier "$1" \
  --auto-minor-version-upgrade \
  --apply-immediately
