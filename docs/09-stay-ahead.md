# Section 9 — Stay Ahead

[← Previous: After the Upgrade](08-after-the-upgrade.md) | [Back to README](../README.md) | [Quick Reference →](10-quick-reference.md)

---

Paste this into your team wiki or runbook after every upgrade:

```
Last upgrade completed    : [date]
Current production version: [fill in]
Next community EOL date   : [check AWS release calendar]
RDS standard support ends : [check AWS release calendar]
Target upgrade version    : [fill in]
Upgrade owner             : [fill in]
Next upgrade review date  : [6 months from today]
Minor version strategy    : Automatic / Manual
Maintenance window        : [day and time]
```

Set a calendar reminder every 6 months to review the AWS release calendar and confirm you are on a supported version with enough runway to plan your next upgrade before EOL pressure forces a rushed migration.

Check the release calendars regularly:
- [RDS PostgreSQL Release Calendar](https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html)
- [Aurora PostgreSQL Release Calendar](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html)
- [PostgreSQL community EOL dates](https://www.postgresql.org/support/versioning/)

---

[← Previous: After the Upgrade](08-after-the-upgrade.md) | [Back to README](../README.md) | [Quick Reference →](10-quick-reference.md)
