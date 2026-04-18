# Section 1 — Know Where You Stand

[← Back to README](../README.md) | [Next: Understand Your EOL Risk →](02-eol-risk.md)

---

### Check version inside any PostgreSQL instance

📄 Script: [scripts/sql/01-check-version.sql](../scripts/sql/01-check-version.sql)

```sql
-- Human-readable version
SELECT version();

-- Numeric version (useful for scripting comparisons)
SELECT current_setting('server_version_num');
```

### Check all your RDS instances at once (AWS CLI)

📄 Script: [scripts/bash/01-check-rds-instances.sh](../scripts/bash/01-check-rds-instances.sh)

```bash
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,EngineVersion,DBInstanceStatus]' \
  --output table
```

### Check across multiple environments in one script

📄 Script: [scripts/bash/02-check-multi-env.sh](../scripts/bash/02-check-multi-env.sh)

```bash
#!/bin/bash
# environments.sh — add your connection strings below
ENVS=(
  "host=dev-db.example.com dbname=myapp user=postgres"
  "host=staging-db.example.com dbname=myapp user=postgres"
  "host=prod-db.example.com dbname=myapp user=postgres"
)

for ENV in "${ENVS[@]}"; do
  echo "--- $ENV ---"
  psql "$ENV" -c "SELECT version();"
done
```

---

[← Back to README](../README.md) | [Next: Understand Your EOL Risk →](02-eol-risk.md)
