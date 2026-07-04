-- ============================================================
-- FINAL PROJECT SQL
-- Topic 8: MedLink Hospital Device Access
-- Group 6
-- MySQL 8.0.16+
-- ============================================================

CREATE DATABASE IF NOT EXISTS medlink_hospital_access
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE medlink_hospital_access;

SELECT VERSION() AS mysql_version;

-- ============================================================
-- 1. RESET AND CREATE BASE TABLES
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP EVENT IF EXISTS ev_cleanup_old_access_audit;
DROP TRIGGER IF EXISTS trg_ai_device_server_access_audit;
DROP TRIGGER IF EXISTS trg_au_device_server_access_audit;

DROP VIEW IF EXISTS vw_department_access_summary;
DROP VIEW IF EXISTS vw_mobile_security_status;
DROP VIEW IF EXISTS vw_staff_service_permissions;
DROP VIEW IF EXISTS vw_active_device_server_access;
DROP VIEW IF EXISTS vw_staff_device_inventory;

DROP PROCEDURE IF EXISTS sp_grant_device_server_access;
DROP PROCEDURE IF EXISTS sp_revoke_device_server_access;
DROP PROCEDURE IF EXISTS sp_grant_staff_service_access;

DROP FUNCTION IF EXISTS fn_staff_device_count;
DROP FUNCTION IF EXISTS fn_mobile_security_label;
DROP FUNCTION IF EXISTS fn_server_active_access_count;

DROP TABLE IF EXISTS device_server_access_audit;
DROP TABLE IF EXISTS device_server_access;
DROP TABLE IF EXISTS mobile_device;
DROP TABLE IF EXISTS fixed_workstation;
DROP TABLE IF EXISTS device;
DROP TABLE IF EXISTS staff_service_access;
DROP TABLE IF EXISTS hospital_service;
DROP TABLE IF EXISTS virtual_server;
DROP TABLE IF EXISTS physical_server;
DROP TABLE IF EXISTS hospital_server;
DROP TABLE IF EXISTS staff_account;
DROP TABLE IF EXISTS staff_member;
DROP TABLE IF EXISTS hospital_department;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE hospital_department (
  department_id VARCHAR(20) PRIMARY KEY,
  department_name VARCHAR(100) NOT NULL,
  internal_mailbox_code VARCHAR(30) NOT NULL,
  phone_number VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_hospital_department_name (department_name)
) ENGINE = InnoDB;

CREATE TABLE staff_member (
  staff_id VARCHAR(20) PRIMARY KEY,
  department_id VARCHAR(20) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  middle_initial CHAR(1),
  job_title VARCHAR(100) NOT NULL,
  CONSTRAINT fk_staff_member_department
    FOREIGN KEY (department_id)
    REFERENCES hospital_department (department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE staff_account (
  staff_id VARCHAR(20) PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_staff_account_username (username),
  CONSTRAINT fk_staff_account_staff_member
    FOREIGN KEY (staff_id)
    REFERENCES staff_member (staff_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE hospital_server (
  server_id VARCHAR(20) PRIMARY KEY,
  server_name VARCHAR(100) NOT NULL,
  manufacturer VARCHAR(100) NOT NULL,
  ip_address VARCHAR(45) NOT NULL,
  operating_system VARCHAR(100) NOT NULL,
  server_room VARCHAR(100) NOT NULL,
  server_type VARCHAR(10) NOT NULL,
  UNIQUE KEY uq_hospital_server_name (server_name),
  UNIQUE KEY uq_hospital_server_ip_address (ip_address),
  CONSTRAINT chk_hospital_server_type
    CHECK (server_type IN ('PHYSICAL', 'VIRTUAL'))
) ENGINE = InnoDB;

CREATE TABLE physical_server (
  server_id VARCHAR(20) PRIMARY KEY,
  CONSTRAINT fk_physical_server_hospital_server
    FOREIGN KEY (server_id)
    REFERENCES hospital_server (server_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE virtual_server (
  server_id VARCHAR(20) PRIMARY KEY,
  physical_host_id VARCHAR(20) NOT NULL,
  CONSTRAINT fk_virtual_server_hospital_server
    FOREIGN KEY (server_id)
    REFERENCES hospital_server (server_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_virtual_server_physical_host
    FOREIGN KEY (physical_host_id)
    REFERENCES physical_server (server_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE hospital_service (
  service_id VARCHAR(20) PRIMARY KEY,
  service_name VARCHAR(100) NOT NULL,
  service_start_date DATE NOT NULL,
  server_id VARCHAR(20) NOT NULL,
  UNIQUE KEY uq_hospital_service_name (service_name),
  KEY idx_hospital_service_server (server_id),
  CONSTRAINT fk_hospital_service_server
    FOREIGN KEY (server_id)
    REFERENCES hospital_server (server_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE staff_service_access (
  staff_id VARCHAR(20) NOT NULL,
  service_id VARCHAR(20) NOT NULL,
  granted_date DATE NOT NULL,
  PRIMARY KEY (staff_id, service_id),
  KEY idx_staff_service_access_service (service_id),
  CONSTRAINT fk_staff_service_access_account
    FOREIGN KEY (staff_id)
    REFERENCES staff_account (staff_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_staff_service_access_service
    FOREIGN KEY (service_id)
    REFERENCES hospital_service (service_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE device (
  device_id VARCHAR(20) PRIMARY KEY,
  staff_id VARCHAR(20) NOT NULL,
  manufacturer VARCHAR(100) NOT NULL,
  model VARCHAR(100) NOT NULL,
  registered_date DATE NOT NULL,
  device_type VARCHAR(12) NOT NULL,
  KEY idx_device_staff_member (staff_id),
  CONSTRAINT chk_device_type
    CHECK (device_type IN ('WORKSTATION', 'MOBILE')),
  CONSTRAINT fk_device_staff_member
    FOREIGN KEY (staff_id)
    REFERENCES staff_member (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE fixed_workstation (
  device_id VARCHAR(20) PRIMARY KEY,
  static_ip_address VARCHAR(45) NOT NULL,
  mac_address VARCHAR(17) NOT NULL,
  building_name VARCHAR(100) NOT NULL,
  room_number VARCHAR(50) NOT NULL,
  UNIQUE KEY uq_fixed_workstation_static_ip (static_ip_address),
  UNIQUE KEY uq_fixed_workstation_mac_address (mac_address),
  CONSTRAINT fk_fixed_workstation_device
    FOREIGN KEY (device_id)
    REFERENCES device (device_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE mobile_device (
  device_id VARCHAR(20) PRIMARY KEY,
  serial_no VARCHAR(80) NOT NULL,
  operating_system VARCHAR(100) NOT NULL,
  os_version VARCHAR(50) NOT NULL,
  screen_lock_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  data_encryption_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  security_eligible BOOLEAN GENERATED ALWAYS AS (
    CASE
      WHEN screen_lock_enabled = TRUE AND data_encryption_enabled = TRUE THEN TRUE
      ELSE FALSE
    END
  ) STORED,
  UNIQUE KEY uq_mobile_device_serial_no (serial_no),
  CONSTRAINT fk_mobile_device_device
    FOREIGN KEY (device_id)
    REFERENCES device (device_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE device_server_access (
  access_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  device_id VARCHAR(20) NOT NULL,
  server_id VARCHAR(20) NOT NULL,
  approved_date DATE NOT NULL,
  revoked_date DATE NULL,
  active_flag TINYINT GENERATED ALWAYS AS (
    CASE
      WHEN revoked_date IS NULL THEN 1
      ELSE NULL
    END
  ) STORED,
  UNIQUE KEY uq_device_server_approved_date (device_id, server_id, approved_date),
  UNIQUE KEY uq_device_server_one_active (device_id, server_id, active_flag),
  KEY idx_device_server_access_server (server_id),
  CONSTRAINT chk_device_server_access_dates
    CHECK (revoked_date IS NULL OR revoked_date >= approved_date),
  CONSTRAINT fk_device_server_access_device
    FOREIGN KEY (device_id)
    REFERENCES device (device_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_device_server_access_server
    FOREIGN KEY (server_id)
    REFERENCES hospital_server (server_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE device_server_access_audit (
  audit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  access_id BIGINT UNSIGNED NOT NULL,
  device_id VARCHAR(20) NOT NULL,
  server_id VARCHAR(20) NOT NULL,
  action_type VARCHAR(20) NOT NULL,
  old_revoked_date DATE NULL,
  new_revoked_date DATE NULL,
  action_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  action_user VARCHAR(100) NOT NULL,
  KEY idx_access_audit_access_time (access_id, action_time),
  CONSTRAINT chk_access_audit_action_type
    CHECK (action_type IN ('GRANT', 'REVOKE')),
  CONSTRAINT fk_access_audit_device_server_access
    FOREIGN KEY (access_id)
    REFERENCES device_server_access (access_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE = InnoDB;

DELIMITER //

CREATE TRIGGER trg_ai_device_server_access_audit
AFTER INSERT ON device_server_access
FOR EACH ROW
BEGIN
  INSERT INTO device_server_access_audit
    (access_id, device_id, server_id, action_type, old_revoked_date, new_revoked_date, action_user)
  VALUES
    (NEW.access_id, NEW.device_id, NEW.server_id, 'GRANT', NULL, NEW.revoked_date, USER());
END //

CREATE TRIGGER trg_au_device_server_access_audit
AFTER UPDATE ON device_server_access
FOR EACH ROW
BEGIN
  IF OLD.revoked_date IS NULL AND NEW.revoked_date IS NOT NULL THEN
    INSERT INTO device_server_access_audit
      (access_id, device_id, server_id, action_type, old_revoked_date, new_revoked_date, action_user)
    VALUES
      (NEW.access_id, NEW.device_id, NEW.server_id, 'REVOKE', OLD.revoked_date, NEW.revoked_date, USER());
  END IF;
END //

CREATE EVENT ev_cleanup_old_access_audit
ON SCHEDULE EVERY 1 MONTH
DISABLE
DO
BEGIN
  DELETE FROM device_server_access_audit
  WHERE action_time < CURRENT_TIMESTAMP - INTERVAL 365 DAY;
END //

DELIMITER ;

SHOW EVENTS FROM medlink_hospital_access LIKE 'ev_cleanup_old_access_audit';

-- ============================================================
-- 2. SAMPLE DATA
-- ============================================================

INSERT INTO hospital_department
  (department_id, department_name, internal_mailbox_code, phone_number)
VALUES
  ('DEP-ER',  'Emergency Department', 'ER-MBX',  '024-1000-1001'),
  ('DEP-CAR', 'Cardiology Department', 'CAR-MBX', '024-1000-1002'),
  ('DEP-LAB', 'Laboratory Department', 'LAB-MBX', '024-1000-1003'),
  ('DEP-IT',  'IT Operations',         'IT-MBX',  '024-1000-1004');

INSERT INTO staff_member
  (staff_id, department_id, last_name, first_name, middle_initial, job_title)
VALUES
  ('STF-001', 'DEP-ER',  'Nguyen', 'An',   'M', 'Emergency Doctor'),
  ('STF-002', 'DEP-CAR', 'Tran',   'Binh', 'T', 'Cardiology Nurse'),
  ('STF-003', 'DEP-LAB', 'Le',     'Chi',  NULL, 'Lab Technician'),
  ('STF-004', 'DEP-IT',  'Pham',   'Dung', 'Q', 'System Administrator'),
  ('STF-005', 'DEP-ER',  'Hoang',  'Minh', NULL, 'Resident Doctor');

INSERT INTO staff_account
  (staff_id, username, password_hash, created_at)
VALUES
  ('STF-001', 'nguyen.an',   'hash_demo_001', '2026-01-05 08:00:00'),
  ('STF-002', 'tran.binh',   'hash_demo_002', '2026-01-06 08:00:00'),
  ('STF-003', 'le.chi',      'hash_demo_003', '2026-01-07 08:00:00'),
  ('STF-004', 'pham.dung',   'hash_demo_004', '2026-01-08 08:00:00');

INSERT INTO hospital_server
  (server_id, server_name, manufacturer, ip_address, operating_system, server_room, server_type)
VALUES
  ('SRV-PHY-01', 'MedLink Core Physical 01', 'Dell',     '10.10.0.11', 'Ubuntu Server 22.04', 'DC-A-R01', 'PHYSICAL'),
  ('SRV-PHY-02', 'MedLink Core Physical 02', 'HPE',      '10.10.0.12', 'Ubuntu Server 22.04', 'DC-A-R02', 'PHYSICAL'),
  ('SRV-VIR-01', 'Electronic Medical Record VM', 'VMware', '10.10.1.21', 'Ubuntu Server 22.04', 'DC-A-VM', 'VIRTUAL'),
  ('SRV-VIR-02', 'Laboratory Information VM',    'VMware', '10.10.1.22', 'Ubuntu Server 22.04', 'DC-A-VM', 'VIRTUAL');

INSERT INTO physical_server (server_id)
VALUES
  ('SRV-PHY-01'),
  ('SRV-PHY-02');

INSERT INTO virtual_server (server_id, physical_host_id)
VALUES
  ('SRV-VIR-01', 'SRV-PHY-01'),
  ('SRV-VIR-02', 'SRV-PHY-02');

INSERT INTO hospital_service
  (service_id, service_name, service_start_date, server_id)
VALUES
  ('SVC-EMR', 'Electronic Medical Record', '2025-09-01', 'SRV-VIR-01'),
  ('SVC-LAB', 'Laboratory Information System', '2025-09-15', 'SRV-VIR-02'),
  ('SVC-SCH', 'Appointment Scheduling', '2025-10-01', 'SRV-VIR-01'),
  ('SVC-COM', 'Internal Communication', '2025-10-10', 'SRV-PHY-02');

INSERT INTO staff_service_access
  (staff_id, service_id, granted_date)
VALUES
  ('STF-001', 'SVC-EMR', '2026-01-10'),
  ('STF-001', 'SVC-SCH', '2026-01-10'),
  ('STF-002', 'SVC-EMR', '2026-01-12'),
  ('STF-002', 'SVC-SCH', '2026-01-12'),
  ('STF-003', 'SVC-LAB', '2026-01-15'),
  ('STF-004', 'SVC-EMR', '2026-01-08'),
  ('STF-004', 'SVC-LAB', '2026-01-08'),
  ('STF-004', 'SVC-COM', '2026-01-08');

INSERT INTO device
  (device_id, staff_id, manufacturer, model, registered_date, device_type)
VALUES
  ('DEV-W-001', 'STF-001', 'HP',      'EliteDesk 800', '2026-01-11', 'WORKSTATION'),
  ('DEV-M-001', 'STF-001', 'Apple',   'iPhone 15',     '2026-01-12', 'MOBILE'),
  ('DEV-M-002', 'STF-002', 'Samsung', 'Galaxy S24',    '2026-01-13', 'MOBILE'),
  ('DEV-W-002', 'STF-003', 'Dell',    'OptiPlex 7010', '2026-01-16', 'WORKSTATION'),
  ('DEV-M-003', 'STF-004', 'Apple',   'iPad Pro',      '2026-01-09', 'MOBILE'),
  ('DEV-W-003', 'STF-004', 'Lenovo',  'ThinkCentre',   '2026-01-09', 'WORKSTATION');

INSERT INTO fixed_workstation
  (device_id, static_ip_address, mac_address, building_name, room_number)
VALUES
  ('DEV-W-001', '10.20.10.21', '00:11:22:33:44:01', 'Emergency Building', 'ER-201'),
  ('DEV-W-002', '10.20.30.31', '00:11:22:33:44:02', 'Laboratory Building', 'LAB-105'),
  ('DEV-W-003', '10.20.40.41', '00:11:22:33:44:03', 'IT Building', 'IT-301');

INSERT INTO mobile_device
  (device_id, serial_no, operating_system, os_version, screen_lock_enabled, data_encryption_enabled)
VALUES
  ('DEV-M-001', 'MOB-APPLE-0001',   'iOS',     '18.1', TRUE, TRUE),
  ('DEV-M-002', 'MOB-SAMSUNG-0002', 'Android', '15',   TRUE, FALSE),
  ('DEV-M-003', 'MOB-APPLE-0003',   'iPadOS',  '18.1', TRUE, TRUE);

INSERT INTO device_server_access
  (device_id, server_id, approved_date, revoked_date)
VALUES
  ('DEV-W-001', 'SRV-VIR-01', '2026-01-12', NULL),
  ('DEV-M-001', 'SRV-VIR-01', '2026-01-13', NULL),
  ('DEV-W-002', 'SRV-VIR-02', '2026-01-17', NULL),
  ('DEV-M-003', 'SRV-PHY-02', '2026-01-10', NULL),
  ('DEV-W-003', 'SRV-VIR-01', '2026-01-10', '2026-02-01');

-- ============================================================
-- 3. INDEXES AND EXECUTION PLAN EVIDENCE
-- ============================================================

CREATE INDEX idx_dsa_server_revoked_device
  ON device_server_access (server_id, revoked_date, device_id);

CREATE INDEX idx_device_type_registered_staff
  ON device (device_type, registered_date, staff_id);

SHOW INDEX FROM device_server_access;

EXPLAIN
SELECT
  dsa.access_id,
  dsa.device_id,
  dsa.server_id,
  dsa.approved_date
FROM device_server_access dsa
WHERE dsa.server_id = 'SRV-VIR-01'
  AND dsa.revoked_date IS NULL
ORDER BY dsa.device_id;

EXPLAIN
SELECT
  d.device_id,
  d.staff_id,
  d.registered_date
FROM device d
WHERE d.device_type = 'MOBILE'
  AND d.registered_date >= '2026-01-01'
ORDER BY d.registered_date;

-- ============================================================
-- 4. VIEWS
-- ============================================================

CREATE OR REPLACE VIEW vw_staff_device_inventory AS
SELECT
  sm.staff_id,
  CONCAT(sm.last_name, ' ', sm.first_name) AS staff_name,
  hd.department_id,
  hd.department_name,
  sm.job_title,
  d.device_id,
  d.device_type,
  d.manufacturer,
  d.model,
  d.registered_date,
  fw.static_ip_address,
  fw.room_number,
  md.operating_system AS mobile_os,
  md.os_version,
  md.security_eligible
FROM staff_member sm
JOIN hospital_department hd
  ON hd.department_id = sm.department_id
LEFT JOIN device d
  ON d.staff_id = sm.staff_id
LEFT JOIN fixed_workstation fw
  ON fw.device_id = d.device_id
LEFT JOIN mobile_device md
  ON md.device_id = d.device_id;

CREATE OR REPLACE VIEW vw_active_device_server_access AS
SELECT
  dsa.access_id,
  dsa.device_id,
  d.device_type,
  CONCAT(sm.last_name, ' ', sm.first_name) AS staff_name,
  hd.department_name,
  dsa.server_id,
  hs.server_name,
  hs.server_type,
  dsa.approved_date
FROM device_server_access dsa
JOIN device d
  ON d.device_id = dsa.device_id
JOIN staff_member sm
  ON sm.staff_id = d.staff_id
JOIN hospital_department hd
  ON hd.department_id = sm.department_id
JOIN hospital_server hs
  ON hs.server_id = dsa.server_id
WHERE dsa.revoked_date IS NULL;

CREATE OR REPLACE VIEW vw_staff_service_permissions AS
SELECT
  sm.staff_id,
  CONCAT(sm.last_name, ' ', sm.first_name) AS staff_name,
  hd.department_name,
  sa.username,
  hs.service_id,
  hs.service_name,
  srv.server_id,
  srv.server_name,
  ssa.granted_date
FROM staff_service_access ssa
JOIN staff_account sa
  ON sa.staff_id = ssa.staff_id
JOIN staff_member sm
  ON sm.staff_id = sa.staff_id
JOIN hospital_department hd
  ON hd.department_id = sm.department_id
JOIN hospital_service hs
  ON hs.service_id = ssa.service_id
JOIN hospital_server srv
  ON srv.server_id = hs.server_id;

CREATE OR REPLACE VIEW vw_mobile_security_status AS
SELECT
  d.device_id,
  CONCAT(sm.last_name, ' ', sm.first_name) AS owner_name,
  md.serial_no,
  md.operating_system,
  md.os_version,
  md.screen_lock_enabled,
  md.data_encryption_enabled,
  md.security_eligible,
  CASE
    WHEN md.security_eligible = 1 THEN 'ELIGIBLE'
    ELSE 'NOT_ELIGIBLE'
  END AS security_status
FROM mobile_device md
JOIN device d
  ON d.device_id = md.device_id
JOIN staff_member sm
  ON sm.staff_id = d.staff_id;

CREATE OR REPLACE VIEW vw_department_access_summary AS
SELECT
  hd.department_id,
  hd.department_name,
  COUNT(DISTINCT sm.staff_id) AS staff_count,
  COUNT(DISTINCT d.device_id) AS registered_device_count,
  COUNT(DISTINCT CASE WHEN dsa.revoked_date IS NULL THEN dsa.access_id END) AS active_server_access_count
FROM hospital_department hd
LEFT JOIN staff_member sm
  ON sm.department_id = hd.department_id
LEFT JOIN device d
  ON d.staff_id = sm.staff_id
LEFT JOIN device_server_access dsa
  ON dsa.device_id = d.device_id
GROUP BY hd.department_id, hd.department_name;

-- ============================================================
-- 5. STORED FUNCTIONS
-- ============================================================

DELIMITER //

CREATE FUNCTION fn_staff_device_count(p_staff_id VARCHAR(20))
RETURNS INT
READS SQL DATA
NOT DETERMINISTIC
BEGIN
  DECLARE v_count INT;

  SELECT COUNT(*)
  INTO v_count
  FROM device
  WHERE staff_id = p_staff_id;

  RETURN v_count;
END //

CREATE FUNCTION fn_mobile_security_label(p_device_id VARCHAR(20))
RETURNS VARCHAR(20)
READS SQL DATA
NOT DETERMINISTIC
BEGIN
  DECLARE v_device_type VARCHAR(12);
  DECLARE v_security TINYINT;

  SELECT device_type
  INTO v_device_type
  FROM device
  WHERE device_id = p_device_id;

  IF v_device_type IS NULL THEN
    RETURN 'NOT_FOUND';
  END IF;

  IF v_device_type <> 'MOBILE' THEN
    RETURN 'NOT_MOBILE';
  END IF;

  SELECT security_eligible
  INTO v_security
  FROM mobile_device
  WHERE device_id = p_device_id;

  IF v_security = 1 THEN
    RETURN 'SECURE';
  END IF;

  RETURN 'INSECURE';
END //

CREATE FUNCTION fn_server_active_access_count(p_server_id VARCHAR(20))
RETURNS INT
READS SQL DATA
NOT DETERMINISTIC
BEGIN
  DECLARE v_count INT;

  SELECT COUNT(*)
  INTO v_count
  FROM device_server_access
  WHERE server_id = p_server_id
    AND revoked_date IS NULL;

  RETURN v_count;
END //

-- ============================================================
-- 6. STORED PROCEDURES
-- ============================================================

CREATE PROCEDURE sp_grant_device_server_access(
  IN p_device_id VARCHAR(20),
  IN p_server_id VARCHAR(20),
  IN p_approved_date DATE
)
BEGIN
  DECLARE v_device_count INT DEFAULT 0;
  DECLARE v_server_count INT DEFAULT 0;
  DECLARE v_active_count INT DEFAULT 0;
  DECLARE v_device_type VARCHAR(12);
  DECLARE v_security TINYINT DEFAULT NULL;

  SELECT COUNT(*), MAX(device_type)
  INTO v_device_count, v_device_type
  FROM device
  WHERE device_id = p_device_id;

  IF v_device_count = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR06: Device does not exist.';
  END IF;

  SELECT COUNT(*)
  INTO v_server_count
  FROM hospital_server
  WHERE server_id = p_server_id;

  IF v_server_count = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR07: Hospital server does not exist.';
  END IF;

  IF v_device_type = 'MOBILE' THEN
    SELECT security_eligible
    INTO v_security
    FROM mobile_device
    WHERE device_id = p_device_id;

    IF COALESCE(v_security, 0) <> 1 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BR08: Mobile device must enable screen lock and encryption before server access.';
    END IF;
  END IF;

  SELECT COUNT(*)
  INTO v_active_count
  FROM device_server_access
  WHERE device_id = p_device_id
    AND server_id = p_server_id
    AND revoked_date IS NULL;

  IF v_active_count > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR09: Device already has an active access grant to this server.';
  END IF;

  INSERT INTO device_server_access
    (device_id, server_id, approved_date, revoked_date)
  VALUES
    (p_device_id, p_server_id, COALESCE(p_approved_date, CURRENT_DATE()), NULL);
END //

CREATE PROCEDURE sp_revoke_device_server_access(
  IN p_access_id BIGINT UNSIGNED,
  IN p_revoked_date DATE
)
BEGIN
  DECLARE v_access_count INT DEFAULT 0;
  DECLARE v_approved_date DATE;
  DECLARE v_existing_revoked_date DATE;

  SELECT COUNT(*), MAX(approved_date), MAX(revoked_date)
  INTO v_access_count, v_approved_date, v_existing_revoked_date
  FROM device_server_access
  WHERE access_id = p_access_id;

  IF v_access_count = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR10: Access record does not exist.';
  END IF;

  IF v_existing_revoked_date IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR11: Access record has already been revoked.';
  END IF;

  IF COALESCE(p_revoked_date, CURRENT_DATE()) < v_approved_date THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR12: Revoked date cannot be earlier than approved date.';
  END IF;

  UPDATE device_server_access
  SET revoked_date = COALESCE(p_revoked_date, CURRENT_DATE())
  WHERE access_id = p_access_id;
END //

CREATE PROCEDURE sp_grant_staff_service_access(
  IN p_staff_id VARCHAR(20),
  IN p_service_id VARCHAR(20),
  IN p_granted_date DATE
)
BEGIN
  DECLARE v_account_count INT DEFAULT 0;
  DECLARE v_service_count INT DEFAULT 0;
  DECLARE v_existing_count INT DEFAULT 0;

  SELECT COUNT(*)
  INTO v_account_count
  FROM staff_account
  WHERE staff_id = p_staff_id;

  IF v_account_count = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR13: Staff must have an account before receiving service permission.';
  END IF;

  SELECT COUNT(*)
  INTO v_service_count
  FROM hospital_service
  WHERE service_id = p_service_id;

  IF v_service_count = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR14: Hospital service does not exist.';
  END IF;

  SELECT COUNT(*)
  INTO v_existing_count
  FROM staff_service_access
  WHERE staff_id = p_staff_id
    AND service_id = p_service_id;

  IF v_existing_count > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'BR15: Staff already has permission to this service.';
  END IF;

  INSERT INTO staff_service_access
    (staff_id, service_id, granted_date)
  VALUES
    (p_staff_id, p_service_id, COALESCE(p_granted_date, CURRENT_DATE()));
END //

DELIMITER ;

-- ============================================================
-- 7. REPORTING QUERIES
-- ============================================================

-- Q01. Filter and order on one base table.
SELECT
  staff_id,
  department_id,
  last_name,
  first_name,
  job_title
FROM staff_member
WHERE department_id = 'DEP-ER'
ORDER BY last_name, first_name;

-- Q02. INNER JOIN across department, staff, device, access and server.
SELECT
  dsa.access_id,
  CONCAT(sm.last_name, ' ', sm.first_name) AS staff_name,
  hd.department_name,
  d.device_id,
  d.device_type,
  hs.server_name,
  hs.server_type,
  dsa.approved_date
FROM device_server_access dsa
JOIN device d
  ON d.device_id = dsa.device_id
JOIN staff_member sm
  ON sm.staff_id = d.staff_id
JOIN hospital_department hd
  ON hd.department_id = sm.department_id
JOIN hospital_server hs
  ON hs.server_id = dsa.server_id
WHERE dsa.revoked_date IS NULL
ORDER BY hs.server_name, staff_name;

-- Q03. Staff service permissions and the hosting server.
SELECT
  staff_id,
  staff_name,
  department_name,
  service_name,
  server_name,
  granted_date
FROM vw_staff_service_permissions
ORDER BY staff_id, service_name;

-- Q04. Mobile device security audit.
SELECT
  device_id,
  owner_name,
  operating_system,
  os_version,
  screen_lock_enabled,
  data_encryption_enabled,
  security_status
FROM vw_mobile_security_status
ORDER BY security_status, device_id;

-- Q05. Server workload summary.
SELECT
  hs.server_id,
  hs.server_name,
  hs.server_type,
  COUNT(DISTINCT svc.service_id) AS service_count,
  fn_server_active_access_count(hs.server_id) AS active_access_count
FROM hospital_server hs
LEFT JOIN hospital_service svc
  ON svc.server_id = hs.server_id
GROUP BY hs.server_id, hs.server_name, hs.server_type
HAVING active_access_count >= 1
ORDER BY active_access_count DESC, service_count DESC;

-- Q06. CTE: aggregate departments with registered devices and active server access.
WITH department_access AS (
  SELECT
    hd.department_id,
    hd.department_name,
    COUNT(DISTINCT sm.staff_id) AS staff_count,
    COUNT(DISTINCT d.device_id) AS registered_device_count,
    COUNT(DISTINCT CASE
      WHEN dsa.revoked_date IS NULL THEN dsa.access_id
    END) AS active_server_access_count
  FROM hospital_department hd
  LEFT JOIN staff_member sm
    ON sm.department_id = hd.department_id
  LEFT JOIN device d
    ON d.staff_id = sm.staff_id
  LEFT JOIN device_server_access dsa
    ON dsa.device_id = d.device_id
  GROUP BY hd.department_id, hd.department_name
)
SELECT
  department_id,
  department_name,
  staff_count,
  registered_device_count,
  active_server_access_count
FROM department_access
WHERE active_server_access_count >= 1
ORDER BY active_server_access_count DESC;

-- Q07. Staff who do not have a login account yet.
SELECT
  sm.staff_id,
  CONCAT(sm.last_name, ' ', sm.first_name) AS staff_name,
  hd.department_name,
  sm.job_title
FROM staff_member sm
JOIN hospital_department hd
  ON hd.department_id = sm.department_id
LEFT JOIN staff_account sa
  ON sa.staff_id = sm.staff_id
WHERE sa.staff_id IS NULL;

-- Q08. Revoked device-server access history.
SELECT
  dsa.access_id,
  dsa.device_id,
  dsa.server_id,
  dsa.approved_date,
  dsa.revoked_date,
  DATEDIFF(dsa.revoked_date, dsa.approved_date) AS active_days
FROM device_server_access dsa
WHERE dsa.revoked_date IS NOT NULL
ORDER BY dsa.revoked_date DESC;

-- Q09. Audit rows created by trigger.
SELECT
  audit_id,
  access_id,
  device_id,
  server_id,
  action_type,
  old_revoked_date,
  new_revoked_date,
  action_time,
  action_user
FROM device_server_access_audit
ORDER BY audit_id;

-- Q10. Servers that do not host any hospital service.
SELECT
  hs.server_id,
  hs.server_name,
  hs.server_type
FROM hospital_server hs
WHERE NOT EXISTS (
  SELECT 1
  FROM hospital_service svc
  WHERE svc.server_id = hs.server_id
)
ORDER BY hs.server_id;

-- ============================================================
-- 8. POSITIVE TESTS
-- ============================================================

SELECT fn_staff_device_count('STF-001') AS stf_001_device_count;

SELECT
  device_id,
  fn_mobile_security_label(device_id) AS mobile_security_label
FROM device
ORDER BY device_id;

CALL sp_grant_staff_service_access('STF-003', 'SVC-COM', '2026-03-01');

CALL sp_grant_device_server_access('DEV-W-003', 'SRV-PHY-01', '2026-03-05');

SET @access_to_revoke := (
  SELECT access_id
  FROM device_server_access
  WHERE device_id = 'DEV-W-003'
    AND server_id = 'SRV-PHY-01'
    AND revoked_date IS NULL
  ORDER BY access_id DESC
  LIMIT 1
);

CALL sp_revoke_device_server_access(@access_to_revoke, '2026-03-20');

SELECT * FROM vw_active_device_server_access ORDER BY access_id;

SELECT * FROM device_server_access_audit ORDER BY audit_id;

SHOW EVENTS FROM medlink_hospital_access LIKE 'ev_cleanup_old_access_audit';

-- ============================================================
-- 9. USER CREATION AND PRIVILEGES
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

-- ============================================================
-- 10. BACKUP AND RESTORE RUNBOOK
-- Run these commands in terminal, not inside MySQL Workbench.
-- Password should be typed interactively; do not hard-code it.
-- ============================================================

-- Backup:
-- mysqldump -u root -p --routines --triggers --events medlink_hospital_access > medlink_hospital_access_YYYYMMDD.sql

-- Restore to a separate test database:
-- CREATE DATABASE medlink_hospital_access_restore_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- mysql -u root -p medlink_hospital_access_restore_test < medlink_hospital_access_YYYYMMDD.sql

-- ============================================================
-- 11. NEGATIVE TESTS
-- Uncomment and run one test at a time because each test is expected to fail.
-- ============================================================

-- NEG-01: Insecure mobile device cannot be granted server access.
-- CALL sp_grant_device_server_access('DEV-M-002', 'SRV-VIR-01', '2026-04-01');

-- NEG-02: Duplicate active access to the same server is blocked.
-- CALL sp_grant_device_server_access('DEV-W-001', 'SRV-VIR-01', '2026-04-02');

-- NEG-03: Staff without account cannot receive service permission.
-- CALL sp_grant_staff_service_access('STF-005', 'SVC-EMR', '2026-04-03');

-- NEG-04: Revoked date cannot be earlier than approved date.
-- SET @access_to_invalid_revoke := (
--   SELECT access_id
--   FROM device_server_access
--   WHERE revoked_date IS NULL
--   ORDER BY access_id
--   LIMIT 1
-- );
-- CALL sp_revoke_device_server_access(@access_to_invalid_revoke, '2025-12-31');

-- NEG-05: CHECK constraint rejects invalid server type.
-- INSERT INTO hospital_server
--   (server_id, server_name, manufacturer, ip_address, operating_system, server_room, server_type)
-- VALUES
--   ('SRV-BAD-01', 'Invalid Server', 'Demo', '10.10.9.99', 'Ubuntu', 'DC-X', 'CLOUD');
