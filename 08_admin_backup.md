# 08_admin_backup.md

## Local Lab Administration

Run the following SQL section with a MySQL account that has `CREATE USER`, `CREATE ROLE` and `GRANT OPTION` privileges. The same commands are also included in `topic08_medlink_final.sql`.

```sql
-- ============================================================
-- 8. USER CREATION AND PRIVILEGES
-- Run this section with a MySQL account that has CREATE USER privilege.
-- ============================================================

DROP USER IF EXISTS 'medlink_admin'@'localhost';
DROP USER IF EXISTS 'medlink_reporter'@'localhost';
DROP USER IF EXISTS 'medlink_operator'@'localhost';
DROP ROLE IF EXISTS 'role_medlink_reporter';
DROP ROLE IF EXISTS 'role_medlink_operator';

CREATE ROLE 'role_medlink_reporter';
CREATE ROLE 'role_medlink_operator';

CREATE USER 'medlink_admin'@'localhost'
  IDENTIFIED BY 'MedlinkAdmin@2026';

CREATE USER 'medlink_reporter'@'localhost'
  IDENTIFIED BY 'MedlinkReporter@2026';

CREATE USER 'medlink_operator'@'localhost'
  IDENTIFIED BY 'MedlinkOperator@2026';

GRANT ALL PRIVILEGES
  ON medlink_hospital_access.*
  TO 'medlink_admin'@'localhost';

GRANT SELECT
  ON medlink_hospital_access.*
  TO 'role_medlink_reporter';

GRANT SELECT, INSERT, UPDATE
  ON medlink_hospital_access.device_server_access
  TO 'role_medlink_operator';

GRANT SELECT, INSERT, UPDATE
  ON medlink_hospital_access.staff_service_access
  TO 'role_medlink_operator';

GRANT SELECT
  ON medlink_hospital_access.vw_active_device_server_access
  TO 'role_medlink_operator';

GRANT SELECT
  ON medlink_hospital_access.vw_staff_service_permissions
  TO 'role_medlink_operator';

GRANT 'role_medlink_reporter'
  TO 'medlink_reporter'@'localhost';

GRANT 'role_medlink_operator'
  TO 'medlink_operator'@'localhost';

SET DEFAULT ROLE 'role_medlink_reporter'
  TO 'medlink_reporter'@'localhost';

SET DEFAULT ROLE 'role_medlink_operator'
  TO 'medlink_operator'@'localhost';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'medlink_admin'@'localhost';
SHOW GRANTS FOR 'medlink_reporter'@'localhost';
SHOW GRANTS FOR 'medlink_operator'@'localhost';
SHOW GRANTS FOR 'role_medlink_reporter';
SHOW GRANTS FOR 'role_medlink_operator';

```

## Backup And Restore

Backup from terminal; MySQL asks for the password interactively:

```bash
mysqldump -u root -p --routines --triggers --events medlink_hospital_access > medlink_hospital_access_YYYYMMDD.sql
```

Restore to a separate test database, never over the source database:

```sql
CREATE DATABASE medlink_hospital_access_restore_test
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

```bash
mysql -u root -p medlink_hospital_access_restore_test < medlink_hospital_access_YYYYMMDD.sql
```

Do not commit or submit real credentials.
