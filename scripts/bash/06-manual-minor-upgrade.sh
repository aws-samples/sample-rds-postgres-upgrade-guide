#!/bin/bash
# Section 7: Apply a specific minor version manually
# WARNING: This script modifies your RDS instance. Review and test in a non-production environment first.
# Usage: ./06-manual-minor-upgrade.sh <db-instance-identifier> <target-version>
# Example: ./06-manual-minor-upgrade.sh my-db 16.7

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <db-instance-identifier> <target-version>"
  echo "Example: $0 my-db 16.7"
  exit 1
fi

aws rds modify-db-instance \
  --db-instance-identifier "$1" \
  --engine-version "$2" \
  --apply-immediately
