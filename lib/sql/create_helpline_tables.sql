-- ============================================================================
-- HELPLINE CONTACTS TABLES
-- ============================================================================

-- Create national_helpline table for national helpline numbers
CREATE TABLE IF NOT EXISTS national_helpline (
  id SERIAL PRIMARY KEY,
  title VARCHAR(100) NOT NULL, -- e.g., 'Police', 'Ambulance', 'Women Helpline'
  phone_number VARCHAR(20) NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0, -- For custom ordering in UI
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create hospital_contacts table for hospital helpline numbers
CREATE TABLE IF NOT EXISTS hospital_contacts (
  id SERIAL PRIMARY KEY,
  hospital_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  location VARCHAR(255), -- e.g., 'Thane', 'Kalwa', 'Mumbra'
  description TEXT,
  display_order INTEGER DEFAULT 0, -- For custom ordering in UI
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_national_helpline_title ON national_helpline(title);
CREATE INDEX IF NOT EXISTS idx_national_helpline_active ON national_helpline(is_active);
CREATE INDEX IF NOT EXISTS idx_national_helpline_order ON national_helpline(display_order);

CREATE INDEX IF NOT EXISTS idx_hospital_contacts_name ON hospital_contacts(hospital_name);
CREATE INDEX IF NOT EXISTS idx_hospital_contacts_location ON hospital_contacts(location);
CREATE INDEX IF NOT EXISTS idx_hospital_contacts_active ON hospital_contacts(is_active);
CREATE INDEX IF NOT EXISTS idx_hospital_contacts_order ON hospital_contacts(display_order);

-- ============================================================================
-- INSERT DATA FOR NATIONAL HELPLINE
-- ============================================================================

INSERT INTO national_helpline (title, phone_number, description, display_order) VALUES
  ('Police', '112', 'National Emergency Police Helpline', 1),
  ('Ambulance', '108', 'National Emergency Ambulance Service', 2),
  ('Women Helpline', '1091', 'Women Emergency Helpline', 3),
  ('Senior Citizen', '1090', 'Senior Citizen Helpline', 4),
  ('Fire', '101', 'Fire Emergency Service', 5),
  ('National Helpline', '14567', 'National Emergency Helpline', 6)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- INSERT DATA FOR HOSPITAL CONTACTS
-- ============================================================================

INSERT INTO hospital_contacts (hospital_name, phone_number, location, description, display_order) VALUES
  ('Civil Hospital Thane', '022-25472582', 'Thane', 'Civil Hospital in Thane', 1),
  ('Chhatrapati Shivaji Maharaj Hospital (Kalwa)', '+91-22-25343', 'Kalwa', 'Government Hospital in Kalwa', 2),
  ('Central Hospital Ulhasnagar', '0251 270 5505', 'Ulhasnagar', 'Central Hospital in Ulhasnagar', 3),
  ('ESIC Hospital (Wagle Estate)', '+91-22-69074777', 'Wagle Estate', 'ESIC Hospital at Wagle Estate', 4),
  ('KDMC Hospital Dombivli (Municipal)', '0251-2480445', 'Dombivli', 'KDMC Municipal Hospital Dombivli', 5),
  ('Indira Gandhi Hospital Bhiwandi', '02522 226 282', 'Bhiwandi', 'Indira Gandhi Hospital in Bhiwandi', 6),
  ('Ulhasnagar Municipal Corporation Super Speciality Hospital', '9872 29960', 'Ulhasnagar', 'UMC Super Speciality Hospital', 7),
  ('Kalyan Dombivali Municipal Clinic', '093 96233', 'Kalyan-Dombivli', 'KDMC Clinic', 8),
  ('Thane Mental Hospital (Neral/Thane)', ' - ', 'Thane/Neral', 'Thane Mental Hospital', 9)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if tables were created successfully
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('national_helpline', 'hospital_contacts');

-- View all national helpline entries
SELECT * FROM national_helpline WHERE is_active = TRUE ORDER BY display_order;

-- View all hospital contacts
SELECT * FROM hospital_contacts WHERE is_active = TRUE ORDER BY display_order;

-- Count of entries
SELECT
  'National Helpline' as table_name,
  COUNT(*) as count
FROM national_helpline
WHERE is_active = TRUE
UNION ALL
SELECT
  'Hospital Contacts' as table_name,
  COUNT(*) as count
FROM hospital_contacts
WHERE is_active = TRUE;
