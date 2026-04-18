-- Section 3: Prerequisites Check — Database object count
-- Major version upgrade duration depends on the number of database objects,
-- not the overall database size. Use these queries to understand your object footprint.

-- Total object count across all types
SELECT count(*) AS total_objects FROM pg_class;

-- Object count by type
SELECT
  CASE relkind
    WHEN 'r' THEN 'table'
    WHEN 'i' THEN 'index'
    WHEN 'S' THEN 'sequence'
    WHEN 'v' THEN 'view'
    WHEN 'm' THEN 'materialized view'
    WHEN 'c' THEN 'composite type'
    WHEN 't' THEN 'TOAST table'
    WHEN 'f' THEN 'foreign table'
    WHEN 'p' THEN 'partitioned table'
    WHEN 'I' THEN 'partitioned index'
    ELSE relkind::text
  END AS object_type,
  count(*) AS count
FROM pg_class
GROUP BY relkind
ORDER BY count DESC;

-- Object count by schema (excluding system schemas)
SELECT n.nspname AS schema, count(*) AS object_count
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
GROUP BY n.nspname
ORDER BY object_count DESC;

-- Total functions and procedures
SELECT count(*) AS total_functions
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema');

-- Total triggers
SELECT count(*) AS total_triggers FROM pg_trigger WHERE NOT tgisinternal;

-- Summary across all databases (run from each database)
SELECT
  current_database() AS database,
  (SELECT count(*) FROM pg_class) AS total_objects,
  (SELECT count(*) FROM pg_class WHERE relkind = 'r') AS tables,
  (SELECT count(*) FROM pg_class WHERE relkind = 'i') AS indexes,
  (SELECT count(*) FROM pg_class WHERE relkind = 'p') AS partitioned_tables,
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname NOT IN ('pg_catalog','information_schema')) AS functions,
  (SELECT count(*) FROM pg_trigger WHERE NOT tgisinternal) AS triggers;

-- Large objects count (can significantly increase upgrade downtime)
SELECT count(*) AS large_object_count FROM pg_largeobject_metadata;
