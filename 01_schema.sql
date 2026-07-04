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
