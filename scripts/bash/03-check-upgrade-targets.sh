#!/bin/bash
# Section 3 & 6: Check which versions you can upgrade to directly
# Usage: ./03-check-upgrade-targets.sh <your-current-version>
# Example: ./03-check-upgrade-targets.sh 14.9

if [ -z "$1" ]; then
  echo "Usage: $0 <current-engine-version>"
  echo "Example: $0 14.9"
  exit 1
fi

aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version "$1" \
  --query 'DBEngineVersions[*].ValidUpgradeTarget[*].{Version:EngineVersion,MajorUpgrade:IsMajorVersionUpgrade}' \
  --output table
