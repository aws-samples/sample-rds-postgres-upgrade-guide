-- Section 4: Check Your Extensions
-- List all installed extensions with version info
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE installed_version IS NOT NULL
ORDER BY name;
