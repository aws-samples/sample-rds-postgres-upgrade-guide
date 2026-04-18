-- Section 8: After the Upgrade — Check for invalid indexes
SELECT schemaname, relname, indexrelname
FROM pg_stat_user_indexes
JOIN pg_index ON pg_index.indexrelid = pg_stat_user_indexes.indexrelid
WHERE pg_index.indisvalid = false;

-- To rebuild a specific index, uncomment:
-- REINDEX INDEX your_index_name;

-- To rebuild all indexes on a table, uncomment:
-- REINDEX TABLE your_table_name;
