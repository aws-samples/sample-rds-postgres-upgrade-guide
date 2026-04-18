#!/bin/bash
# Section 1: Check version across multiple environments
# Update the connection strings below with your actual environments
ENVS=(
  "host=dev-db.example.com dbname=myapp user=postgres"
  "host=staging-db.example.com dbname=myapp user=postgres"
  "host=prod-db.example.com dbname=myapp user=postgres"
)

for ENV in "${ENVS[@]}"; do
  echo "--- $ENV ---"
  psql "$ENV" -c "SELECT version();"
done
