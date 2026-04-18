#!/bin/bash
# Section 1: Check all your RDS instances at once
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,EngineVersion,DBInstanceStatus]' \
  --output table
