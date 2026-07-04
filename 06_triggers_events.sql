-- ============================================================
-- PART 06: TRIGGERS AND DISABLED EVENT
-- ============================================================

USE medlink_hospital_access;

-- Run after 01_schema.sql and before 02_seed_data.sql if seed audit rows are needed.

DROP EVENT IF EXISTS ev_cleanup_old_access_audit;
DROP TRIGGER IF EXISTS trg_ai_device_server_access_audit;
DROP TRIGGER IF EXISTS trg_au_device_server_access_audit;

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
