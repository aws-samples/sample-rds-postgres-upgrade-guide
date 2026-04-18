# Section 2 — Understand Your EOL Risk

[← Previous: Know Where You Stand](01-know-where-you-stand.md) | [Back to README](../README.md) | [Next: Prerequisites Check →](03-prerequisites.md)

---

Rather than maintaining a static table here that may become outdated, always refer directly to the official AWS documentation for the latest support dates — including community EOL, RDS standard support end, extended support start/end, and pricing tier changes.

**RDS for PostgreSQL release calendar (standard + extended support dates):**
👉 https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html

**Aurora PostgreSQL release calendar (standard + extended support dates):**
👉 https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html

**Key things to check in the table:**
- `Community end of life date` — when the open source community stops patching
- `RDS end of standard support date` — when AWS standard support ends
- `RDS start of Extended Support year 1 pricing` — when additional charges begin
- `RDS start of Extended Support year 3 pricing` — when charges increase further
- `RDS end of Extended Support date` — hard deadline, no more patches after this

> **Tip:** You can also query support dates programmatically via the AWS CLI:
> ```bash
> aws rds describe-db-major-engine-versions --engine postgres
> ```

---

[← Previous: Know Where You Stand](01-know-where-you-stand.md) | [Back to README](../README.md) | [Next: Prerequisites Check →](03-prerequisites.md)
