-- Section 3: Prerequisites Check — Unsupported data types
-- Check for reg* data type usage (except regtype and regclass which are safe)
SELECT n.nspname AS schema, c.relname AS table, a.attname AS column, t.typname AS type
FROM pg_attribute a
JOIN pg_class c ON a.attrelid = c.oid
JOIN pg_type t ON a.atttypid = t.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.typname IN ('regproc','regprocedure','regoper','regoperator','regconfig','regdictionary')
  AND c.relkind = 'r'
  AND NOT a.attisdropped;
