-- Quick Reference Commands

-- Version check
SELECT version();

-- Installed extensions vs available versions
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE installed_version IS NOT NULL ORDER BY name;

-- Invalid indexes
SELECT schemaname, relname, indexrelname
FROM pg_stat_user_indexes
JOIN pg_index ON pg_index.indexrelid = pg_stat_user_indexes.indexrelid
WHERE pg_index.indisvalid = false;

-- Open prepared transactions (must be zero before major upgrade)
SELECT count(*) FROM pg_catalog.pg_prepared_xacts;

-- Active replication slots (must be cleared before major upgrade)
SELECT * FROM pg_replication_slots WHERE slot_type NOT LIKE 'physical';

-- Rebuild statistics after upgrade
ANALYZE VERBOSE;

-- Update an extension (replace extension_name with actual name)
-- ALTER EXTENSION extension_name UPDATE;

-- Check database sizes
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database ORDER BY pg_database_size(datname) DESC;
