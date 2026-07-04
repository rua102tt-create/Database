-- ============================================================
-- PART 03: REPORTING QUERIES
-- ============================================================

USE medlink_hospital_access;

-- Run after views and routines have been created.

-- ============================================================
-- 3. REPORTING QUERIES
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
