#!/bin/bash
# Section 3: List all available PostgreSQL versions on RDS
aws rds describe-db-engine-versions \
  --engine postgres \
  --query 'DBEngineVersions[*].EngineVersion' \
  --output table
