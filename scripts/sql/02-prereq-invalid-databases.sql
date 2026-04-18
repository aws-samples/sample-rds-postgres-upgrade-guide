-- Section 3: Prerequisites Check — Invalid databases, prepared transactions, replication slots

-- Check for invalid databases
SELECT datname, datistemplate, datallowconn
FROM pg_database;

-- Check for open prepared transactions (must be zero before upgrading)
SELECT count(*) FROM pg_catalog.pg_prepared_xacts;

-- Check for active logical replication slots (must be dropped before upgrading)
SELECT * FROM pg_replication_slots WHERE slot_type NOT LIKE 'physical';
