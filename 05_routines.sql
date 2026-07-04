-- ============================================================
-- PART 05: STORED FUNCTIONS AND PROCEDURES
-- ============================================================

USE medlink_hospital_access;

-- ============================================================
-- 5.1 STORED FUNCTIONS
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
-- 5.2 STORED PROCEDURES
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
