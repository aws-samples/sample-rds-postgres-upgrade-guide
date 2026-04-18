-- Section 3: Prerequisites Check — Disk space
-- Check current database sizes
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Check total size of the current database
SELECT pg_size_pretty(pg_database_size(current_database())) AS total_size;
