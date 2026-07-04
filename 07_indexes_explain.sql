-- ============================================================
-- PART 07: INDEXES AND EXPLAIN
-- ============================================================

USE medlink_hospital_access;

-- ============================================================
-- 7. INDEXES AND EXECUTION PLAN EVIDENCE
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
