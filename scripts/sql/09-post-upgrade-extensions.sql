-- Section 8: After the Upgrade — Check and update extensions
-- Check installed vs available extension versions
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE installed_version IS NOT NULL
ORDER BY name;

-- Generate UPDATE statements for all extensions that are behind
SELECT 'ALTER EXTENSION ' || name || ' UPDATE;'
FROM pg_available_extensions
WHERE installed_version IS NOT NULL
  AND installed_version <> default_version;
