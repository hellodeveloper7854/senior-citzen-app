# Helpline Database Setup Instructions

This document provides the SQL code and instructions to set up the helpline contacts database for fetching data dynamically.

## Step 1: Execute SQL Script

Run the SQL script located at `lib/sql/create_helpline_tables.sql` in your Supabase SQL Editor.

You can find the complete SQL file at:
**`lib/sql/create_helpline_tables.sql`**

## Step 2: SQL Script Content

The script creates two tables and inserts all existing data:

### 1. National Helpline Table

```sql
CREATE TABLE IF NOT EXISTS national_helpline (
  id SERIAL PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Data Inserted:**
- Police: 112
- Ambulance: 108
- Women Helpline: 1091
- Senior Citizen: 1090
- Fire: 101
- National Helpline: 14567

### 2. Hospital Contacts Table

```sql
CREATE TABLE IF NOT EXISTS hospital_contacts (
  id SERIAL PRIMARY KEY,
  hospital_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  location VARCHAR(255),
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Data Inserted:**
- Civil Hospital Thane: 022-25472582
- Chhatrapati Shivaji Maharaj Hospital (Kalwa): +91-22-25343
- Central Hospital Ulhasnagar: 0251 270 5505
- ESIC Hospital (Wagle Estate): +91-22-69074777
- KDMC Hospital Dombivli (Municipal): 0251-2480445
- Indira Gandhi Hospital Bhiwandi: 02522 226 282
- Ulhasnagar Municipal Corporation Super Speciality Hospital: 9872 29960
- Kalyan Dombivali Municipal Clinic: 093 96233
- Thane Mental Hospital (Neral/Thane): -

## Step 3: Code Changes Made

### SupabaseService Methods Added

File: `lib/services/supabase_service.dart`

Three new methods have been added:

1. **getNationalHelplines()** - Fetches all active national helpline numbers
2. **getHospitalContacts()** - Fetches all active hospital contact numbers
3. **getEmergencyPhoneNumber(serviceName)** - Fetches emergency phone number by service name

### Screen Updates

Both screens have been converted to StatefulWidget and now fetch data dynamically:

1. **National Helpline Screen** (`lib/screens/national_helpline_screen.dart`)
   - Changed from StatelessWidget to StatefulWidget
   - Added loading indicator
   - Fetches data from `national_helpline` table
   - Shows error message if no data available

2. **Hospital Helpline Screen** (`lib/screens/hospital_helpline_screen.dart`)
   - Changed from StatelessWidget to StatefulWidget
   - Added loading indicator
   - Fetches data from `hospital_contacts` table
   - Shows error message if no data available

## Step 4: How to Add/Update Data

### To Add New Helpline Numbers:

```sql
-- For National Helpline
INSERT INTO national_helpline (title, phone_number, description, display_order)
VALUES ('New Service', '12345', 'Description', 7);

-- For Hospital Contacts
INSERT INTO hospital_contacts (hospital_name, phone_number, location, description, display_order)
VALUES ('New Hospital', '022-12345678', 'Location', 'Description', 10);
```

### To Update Existing Numbers:

```sql
-- For National Helpline
UPDATE national_helpline
SET phone_number = 'NewNumber', description = 'New Description'
WHERE title = 'Police';

-- For Hospital Contacts
UPDATE hospital_contacts
SET phone_number = 'NewNumber', location = 'New Location'
WHERE hospital_name = 'Civil Hospital Thane';
```

### To Deactivate (Hide) Numbers:

```sql
-- Soft delete - keeps data but hides from app
UPDATE national_helpline SET is_active = FALSE WHERE id = 1;
UPDATE hospital_contacts SET is_active = FALSE WHERE id = 1;
```

## Step 5: Verification

After executing the SQL script, run these verification queries:

```sql
-- Check national helpline data
SELECT * FROM national_helpline WHERE is_active = TRUE ORDER BY display_order;

-- Check hospital contacts data
SELECT * FROM hospital_contacts WHERE is_active = TRUE ORDER BY display_order;

-- Count records
SELECT COUNT(*) FROM national_helpline WHERE is_active = TRUE;
SELECT COUNT(*) FROM hospital_contacts WHERE is_active = TRUE;
```

## Benefits of This Approach

1. **Dynamic Updates**: Add, update, or remove helpline numbers without app updates
2. **Centralized Management**: All contact numbers managed in one place
3. **Easy Maintenance**: Update numbers through SQL or Supabase dashboard
4. **Soft Delete**: Use `is_active` flag to hide numbers without deleting data
5. **Custom Ordering**: Use `display_order` to control the order in app
6. **Scalability**: Easy to add more fields like email, website, working hours, etc.

## Table Relationships

Both tables are independent and don't have foreign key relationships. They can be managed separately.

## Indexes Created

For better query performance, indexes have been created on:
- `national_helpline`: title, is_active, display_order
- `hospital_contacts`: hospital_name, location, is_active, display_order

## Notes

- All phone numbers are stored as strings to preserve formatting
- The `display_order` field controls the order in which contacts appear in the app
- The `is_active` field allows soft-delete functionality
- The `location` field in hospital_contacts helps users identify nearby hospitals
