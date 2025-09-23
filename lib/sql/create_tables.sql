-- Create user_credentials table (registrations table already exists)
-- Add optional profile picture column to registrations
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

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