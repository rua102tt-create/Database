-- ============================================================
-- PART 04: VIEWS
-- ============================================================

USE medlink_hospital_access;

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
