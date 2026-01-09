# Police Station Contact Feature

## Overview
This feature displays the police station contact number on the "Under Verification" screen when a user's status is Pending. If the police station hasn't provided their contact number, it falls back to the SOS emergency number.

## Database Table

### Table: `police_station_contacts`

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Primary key (auto-generated) |
| station_name | VARCHAR(255) | Name of the police station (must match registrations.police_station) |
| contact_number | VARCHAR(20) | Contact phone number for the station |
| is_active | BOOLEAN | Whether this contact is currently active (default: true) |
| created_at | TIMESTAMP | Auto-generated timestamp |
| updated_at | TIMESTAMP | Auto-updated timestamp |

## Setup Instructions

### 1. Create the Database Table

Run the SQL script in your Supabase SQL Editor:
```bash
# Run the SQL file
database_setup/police_station_contacts_table.sql
```

Or manually execute the SQL in Supabase SQL Editor.

### 2. Insert Police Station Contacts

Add contact numbers for each police station:

```sql
INSERT INTO public.police_station_contacts (station_name, contact_number, is_active) VALUES
('Thane City Police Station', '022-25345678', true),
('Kalwa Police Station', '022-25345679', true),
('Mumbra Police Station', '022-25345680', true),
('Diva Police Station', '022-25345681', true),
('Kopri Police Station', '022-25345682', true);
```

**Important**: The `station_name` must exactly match the `police_station` value in the `registrations` table.

### 3. Configure Emergency Phone Numbers

Ensure your `emergency_phone_numbers` table has the SOS number:

```sql
-- Check if SOS number exists
SELECT * FROM emergency_phone_numbers WHERE service_name = 'Police';

-- If not exists, insert it
INSERT INTO emergency_phone_numbers (service_name, phone_number, is_active)
VALUES ('Police', '100', true);
```

## How It Works

### Flow:

1. **User Enrolls**: User completes registration and their status is set to "Pending"
2. **Screen Display**: User sees the "Under Verification" screen
3. **Load Station Info**:
   - System retrieves user's assigned police station from their profile
   - System queries `police_station_contacts` table for the station's number
4. **Display Logic**:
   - **If police station number exists**: Shows the station name and contact number
   - **If no station number found**: Shows "Police Emergency" with SOS number (100)
   - **If no police station assigned**: Shows SOS number directly

### Code Implementation:

#### In `supabase_service.dart`:

1. **`getPoliceStationContactNumber(String policeStation)`**
   - Retrieves contact number for a specific police station
   - Returns null if not found

2. **`getPoliceStationNumberWithSOSFallback(String policeStation)`**
   - First tries to get police station specific number
   - Falls back to SOS emergency number if station number not available
   - Returns '100' as final fallback

#### In `under_verification_screen.dart`:

1. **`initState()`**: Calls `_loadPoliceStationNumber()` to fetch contact info
2. **`_loadPoliceStationNumber()`**:
   - Gets current user's email
   - Retrieves user profile to find police station
   - Calls `getPoliceStationNumberWithSOSFallback()`
   - Updates UI with the contact number
3. **UI Updates**: Displays contact information with a call button

## Features

### User-Facing:
- ✅ Shows police station contact number on verification screen
- ✅ One-tap calling functionality
- ✅ Fallback to SOS number if station contact not available
- ✅ Loading indicator while fetching data
- ✅ Clean, card-based UI design

### Backend:
- ✅ Automatic fallback chain (Station → SOS → 100)
- ✅ Error handling with graceful degradation
- ✅ Indexed database for fast queries
- ✅ RLS policies for security
- ✅ Auto-updating timestamps

## Testing

### Test Case 1: Police Station Has Contact Number
1. Add a station to `police_station_contacts` table
2. Register a user with that police station
3. Verify the screen shows the station's contact number

### Test Case 2: No Station Contact (Fallback to SOS)
1. Register a user with a police station NOT in `police_station_contacts`
2. Verify the screen shows "Police Emergency" with SOS number

### Test Case 3: No Police Station Assigned
1. Register a user without a police station
2. Verify the screen shows SOS number

### Test Case 4: Call Button
1. Tap the "Call" button
2. Verify the phone dialer opens with the correct number

## Maintenance

### Adding New Stations:
When adding new police stations, insert their contact numbers:
```sql
INSERT INTO public.police_station_contacts (station_name, contact_number, is_active)
VALUES ('New Station Name', '022-XXXXXXXX', true);
```

### Updating Contact Numbers:
```sql
UPDATE public.police_station_contacts
SET contact_number = '022-YYYYYYYY'
WHERE station_name = 'Station Name';
```

### Deactivating a Station:
```sql
UPDATE public.police_station_contacts
SET is_active = false
WHERE station_name = 'Station Name';
```

## Security Notes

- The table uses Row Level Security (RLS)
- Public users can only read active contacts
- Only service_role can insert/update/delete records
- Sensitive operations require proper authentication

## Future Enhancements

Potential improvements:
- Add multiple contact numbers per station (e.g., duty officer, helpline)
- Add email addresses for stations
- Add station operating hours
- Show distance to nearest station
- Add WhatsApp contact option
- Multi-language support for station names
