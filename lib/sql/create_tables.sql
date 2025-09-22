-- Create user_credentials table (registrations table already exists but add profile_photo_url if needed)
-- ALTER TABLE registrations ADD COLUMN profile_photo_url TEXT;

CREATE TABLE user_credentials (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);