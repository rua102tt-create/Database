-- ============================================================
-- PART 02: SAMPLE DATA
-- ============================================================

USE medlink_hospital_access;

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
