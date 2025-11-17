-- Create user_credentials table (registrations table already exists)

-- Add optional profile picture column to registrations
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- Add disability columns to registrations table
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS is_physically_disabled BOOLEAN DEFAULT FALSE;
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS disability_type TEXT;

-- Add status column if it doesn't exist (for user verification status)
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending';

-- Add rejection reason column if it doesn't exist
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Add unique constraint on contact_number to prevent duplicate phone numbers in profiles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_reg_contact_number') THEN
        ALTER TABLE registrations ADD CONSTRAINT unique_reg_contact_number UNIQUE (contact_number);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS user_credentials (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Add unique constraint on phone_number to prevent duplicate phone numbers for login
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_phone_number') THEN
        ALTER TABLE user_credentials ADD CONSTRAINT unique_phone_number UNIQUE (phone_number);
    END IF;
END $$;

-- Create SOS alerts table for admin monitoring
CREATE TABLE IF NOT EXISTS sos_alerts (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL, -- phone number as identifier
    user_name VARCHAR(255),
    police_station VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_address TEXT,
    emergency_contacts TEXT[], -- array of emergency contact numbers
    alert_timestamp TIMESTAMP DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active', -- active, resolved, false_alarm
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(255),
    notes TEXT
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_sos_alerts_user_id ON sos_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status ON sos_alerts(status);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_timestamp ON sos_alerts(alert_timestamp);

-- Create audio_recordings table for storing voice recordings
CREATE TABLE IF NOT EXISTS audio_recordings (
  id SERIAL PRIMARY KEY,
  user_phone VARCHAR(20) NOT NULL,
  police_station VARCHAR(255),
  audio_url TEXT NOT NULL,
  recorded_at TIMESTAMP NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'reviewed', 'archived'
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_audio_recordings_user_phone ON audio_recordings(user_phone);
CREATE INDEX IF NOT EXISTS idx_audio_recordings_status ON audio_recordings(status);
CREATE INDEX IF NOT EXISTS idx_audio_recordings_recorded_at ON audio_recordings(recorded_at DESC);

-- Create complaints table for user complaints
CREATE TABLE IF NOT EXISTS complaints (
  id SERIAL PRIMARY KEY,
  user_phone VARCHAR(20) NOT NULL,
  police_station VARCHAR(255),
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  incident_date DATE,
  incident_time TIME,
  location TEXT,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'under_review', 'resolved', 'rejected'
  submitted_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  admin_notes TEXT,
  FOREIGN KEY (user_phone) REFERENCES registrations(contact_number) ON DELETE CASCADE
);

-- Create indexes for complaints table
CREATE INDEX IF NOT EXISTS idx_complaints_user_phone ON complaints(user_phone);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_submitted_at ON complaints(submitted_at);

-- ============================================================================
-- VERIFICATION QUERIES - Run these to check if everything is set up correctly
-- ============================================================================

-- Check all tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('registrations', 'user_credentials', 'sos_alerts', 'audio_recordings', 'complaints');

-- Check if all required columns exist in registrations table
SELECT column_name FROM information_schema.columns
WHERE table_name = 'registrations'
AND column_name IN ('profile_photo_url', 'is_physically_disabled', 'disability_type', 'status', 'rejection_reason');

-- Check if constraints exist
SELECT conname, consrc FROM pg_constraint
WHERE conrelid = 'registrations'::regclass
AND conname LIKE '%unique%';

-- Check storage buckets (run this in Supabase Dashboard > Storage)
-- You should see: profile-photos, audio-recordings

-- ============================================================================
-- EMERGENCY PHONE NUMBERS TABLE
-- ============================================================================

-- Create emergency_phone_numbers table for storing emergency contact numbers
CREATE TABLE IF NOT EXISTS emergency_phone_numbers (
  id SERIAL PRIMARY KEY,
  service_name VARCHAR(100) NOT NULL, -- e.g., 'Police', 'Ambulance', 'Fire Department'
  phone_number VARCHAR(20) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_emergency_phone_numbers_service ON emergency_phone_numbers(service_name);
CREATE INDEX IF NOT EXISTS idx_emergency_phone_numbers_active ON emergency_phone_numbers(is_active);



-- Command to insert new emergency phone number:
-- INSERT INTO emergency_phone_numbers (service_name, phone_number, description)
-- VALUES ('ServiceName', 'PhoneNumber', 'Description');
-- Example:
-- INSERT INTO emergency_phone_numbers (service_name, phone_number, description)
-- VALUES ('Women Helpline', '1091', 'Women Emergency Helpline');

-- Verification query for emergency phone numbers table
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name = 'emergency_phone_numbers';