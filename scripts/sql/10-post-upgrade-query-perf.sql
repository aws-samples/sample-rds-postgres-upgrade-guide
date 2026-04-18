-- Section 8: After the Upgrade — Monitor query performance with pg_stat_statements
-- Reset to get a clean post-upgrade baseline
SELECT pg_stat_statements_reset();

-- After a few hours, check slowest queries by mean execution time
SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
