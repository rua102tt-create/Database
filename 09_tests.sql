-- ============================================================
-- PART 09: POSITIVE AND NEGATIVE TESTS
-- ============================================================

USE medlink_hospital_access;

-- Run negative tests one by one because each one is expected to fail.

-- ============================================================
-- 9.1 POSITIVE TESTS
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
-- 9.2 NEGATIVE TESTS
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
