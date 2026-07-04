# DBMS Final Project - Group 6 - Topic 8

## Project

MedLink Hospital Device Access

## Environment

- MySQL 8.0.16+; this version is required because the project uses enforced `CHECK` constraints.
- Storage engine: InnoDB
- Character set: utf8mb4
- Recommended client: MySQL Workbench

## Files

- `topic08_medlink_final_report.tex`: LaTeX report.
- `topic08_medlink_final.sql`: full executable SQL script.
- `01_schema.sql`: database, reset statements and table definitions.
- `02_seed_data.sql`: sample data.
- `03_queries.sql`: reporting queries.
- `04_views.sql`: view definitions.
- `05_routines.sql`: stored functions and stored procedures.
- `06_triggers_events.sql`: audit triggers and disabled cleanup event.
- `07_indexes_explain.sql`: secondary indexes, `SHOW INDEX` and `EXPLAIN`.
- `08_admin_backup.md`: local user/role/grant commands and backup/restore runbook.
- `09_tests.sql`: positive tests and commented negative tests.
- `figures/`: screenshots and ERD image used in the report.

## Run Order

Open `topic08_medlink_final.sql` in MySQL Workbench and run the script from top to bottom.

For the split submission files, run in this order:

1. `01_schema.sql`
2. `06_triggers_events.sql`
3. `02_seed_data.sql`
4. `07_indexes_explain.sql`
5. `04_views.sql`
6. `05_routines.sql`
7. `03_queries.sql`
8. `09_tests.sql`
9. Use `08_admin_backup.md` for local administration and backup/restore commands.

The trigger/event file is placed before seed data in the split run order so audit rows are generated while sample access records are inserted, matching the full script behavior.

The script creates:

- database and base tables
- seed data
- audit table and triggers
- disabled cleanup event for old audit rows
- indexes and EXPLAIN evidence
- views
- stored functions
- stored procedures
- reporting queries
- positive tests
- local lab users, roles, and grants

Negative tests are commented out at the end of the script. Run them one at a time because each negative test is expected to fail.

## Demo Users

The script creates local lab users:

- `medlink_admin`@`localhost`
- `medlink_reporter`@`localhost`
- `medlink_operator`@`localhost`

The script also creates roles:

- `role_medlink_reporter`
- `role_medlink_operator`

Reporter/operator users receive default roles according to the least-privilege design.

Passwords are demo-only and must not be reused in a real system.

## Backup And Restore

Backup from terminal:

```bash
mysqldump -u root -p --routines --triggers --events medlink_hospital_access > medlink_hospital_access_YYYYMMDD.sql
```

Restore to a separate test database:

```sql
CREATE DATABASE medlink_hospital_access_restore_test
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

```bash
mysql -u root -p medlink_hospital_access_restore_test < medlink_hospital_access_YYYYMMDD.sql
```

Do not hard-code or submit real passwords.
