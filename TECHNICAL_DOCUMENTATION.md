# Snehaband (आधारवाड ठाणे पोलीस) - Technical Documentation

## Overview
**Snehaband** (formerly Aadharwad Thane Police) is a senior citizen safety application with SOS alerts, live location tracking, emergency contacts, and volunteer networking capabilities.

---

## Frontend Tech Stack

### Core Framework
- **Flutter** - Cross-platform mobile application framework
  - SDK Version: `>=3.3.3 <4.0.0`
  - Current Version: `1.2.0+7`

### Key Dependencies

#### UI & Design
- **cupertino_icons**: `^1.0.6` - iOS-style icons
- **font_awesome_flutter**: `^10.5.0` - Font Awesome icons
- **google_fonts**: `^6.3.0` - Google fonts integration
- **flutter_launcher_icons**: `^0.14.4` - App launcher icons
- **flutter_native_splash**: `^2.4.0` - Native splash screen

#### Data Storage & Security
- **shared_preferences**: `^2.2.2` - Local key-value storage
- **flutter_secure_storage**: `^9.0.0` - Secure storage for sensitive data
- **cryptography**: `^2.7.0` - Cryptographic operations (AES-256 encryption)

#### Media & Recording
- **image_picker**: `^1.0.7` - Image selection from gallery/camera
- **record**: `^6.1.2` - Audio recording
- **audioplayers**: `^6.0.0` - Audio playback

#### Location Services
- **geolocator**: `^11.0.0` - Location tracking
- **geocoding**: `^3.0.0` - Geocoding (address ↔ coordinates)
- **google_maps_flutter**: `^2.6.1` - Google Maps integration

#### Networking & API
- **http**: `^1.2.1` - HTTP requests
- **http_parser**: `^4.0.2` - HTTP parsing utilities
- **url_launcher**: `^6.2.6` - Launch URLs, phone calls, etc.

#### Permissions & Notifications
- **permission_handler**: `^11.0.1` - Runtime permissions
- **flutter_local_notifications**: `^17.0.0` - Local notifications

#### Background Tasks
- **background_fetch**: `^1.2.1` - Background location tracking

#### Configuration
- **flutter_dotenv**: `^5.1.0` - Environment variable management

---

## Backend Tech Stack

### Core Framework
- **Node.js** - JavaScript runtime
  - Version: `>=16.0.0`
- **Express.js** - Web application framework
  - Version: `^4.22.1`

### Key Dependencies

#### Database
- **pg** (node-postgres): `^8.11.3` - PostgreSQL client for Node.js

#### Middleware & Utilities
- **cors**: `^2.8.5` - Cross-Origin Resource Sharing
- **multer**: `^2.0.2` - File upload handling (multipart/form-data)
- **dotenv**: `^16.3.1` - Environment configuration

#### Cloud Storage
- **@supabase/supabase-js**: `^2.39.0` - Supabase client for audio file storage

#### Development
- **nodemon**: `^3.0.2` - Auto-restart on file changes

---

## Database

### Primary Database
- **PostgreSQL** (Production Database)
  - **Host**: `94.249.213.97`
  - **Port**: `5432`
  - **Database Name**: `seniorcitizen`
  - **User**: `postgres`

### Database Connection Pool
```javascript
{
  max: 20,                          // Maximum connections
  idleTimeoutMillis: 30000,         // 30 seconds
  connectionTimeoutMillis: 2000     // 2 seconds
}
```

### Key Tables
1. **registrations** - User registration profiles
2. **user_credentials** - Authentication credentials (email, password)
3. **audio_recordings** - Audio recordings with metadata
4. **complaints** - User complaints/reports
5. **sos_alerts** - SOS emergency alerts
6. **hospital_contacts** - Hospital emergency contacts
7. **national_helpline** - National helpline numbers
8. **user_feedback** - User feedback and ratings

---


## Backend Deployment

### Deployment Platform
- **Vercel** - Serverless deployment platform
- **Configuration File**: `backend/vercel.json`

### Deployment Configuration
```json
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ]
}
```

### Server Runtime
- **Port**: Configured via environment variable (default: `3000`)
- **Listener**: `0.0.0.0` (all network interfaces)
- **Graceful Shutdown**: Handles SIGINT and SIGTERM signals

---

## Data Encryption & Security

### Client-Side Encryption (Flutter)

#### Encryption Method
- **Algorithm**: AES-CBC (Advanced Encryption Standard - Cipher Block Chaining)
- **Key Size**: 256 bits
- **Library**: `cryptography` package (`^2.7.0`)

#### Encryption Implementation
**File**: `lib/utils/crypto_util.dart`

```dart
static final AesCbc _algorithm = AesCbc.with256bits(
  macAlgorithm: MacAlgorithm.empty
);
static final SecretKey _key = SecretKey(
  utf8.encode('ThaneMitrSecretKey1234567890abcd') // 32 bytes
);
static final List<int> _iv = utf8.encode('VectorInit123456'); // 16 bytes
```

#### Encryption Process
1. **Input**: Plain text string
2. **Encoding**: UTF-8 encoding
3. **Encryption**: AES-256-CBC with fixed key and IV
4. **Output**: Base64-encoded ciphertext

#### Decryption Process
1. **Input**: Base64-encoded ciphertext
2. **Decoding**: Base64 decoding
3. **Decryption**: AES-256-CBC with fixed key and IV
4. **Output**: Original plain text string
5. **Fallback**: Returns original string if decryption fails

#### Encrypted Data Types
- Sensitive user data stored locally on device
- Application state data
- Any data marked for encryption before storage

### Backend Security



#### Data Transmission
- **Protocol**: HTTPS (encrypted in transit)
- **API**: RESTful endpoints with JSON payload

#### File Uploads
- **Size Limit**: 50MB maximum
- **Storage**: Memory storage using multer
- **Upload**: Stream to Supabase Storage

---

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:contactNumber` - Get user by contact number
- `POST /api/users` - Create new user
- `PUT /api/users/:contactNumber` - Update user

### Audio Recordings
- `GET /api/recordings` - Get all recordings
- `GET /api/recordings/:id` - Get single recording
- `POST /api/recordings` - Upload audio recording
- `PATCH /api/recordings/:id/status` - Update recording status

### Complaints
- `GET /api/complaints` - Get all complaints
- `GET /api/complaints/:id` - Get single complaint
- `POST /api/complaints` - Create complaint
- `PATCH /api/complaints/:id/status` - Update complaint status

### SOS Alerts
- `GET /api/sos-alerts` - Get all SOS alerts
- `GET /api/sos-alerts/:id` - Get single SOS alert
- `POST /api/sos-alerts` - Create SOS alert
- `PATCH /api/sos-alerts/:id/status` - Update SOS alert status
- `GET /api/sos-alerts/active/count` - Get active SOS count

### Hospital Contacts
- `GET /api/hospital-contacts` - Get hospital contacts

### National Helplines
- `GET /api/national-helplines` - Get national helpline numbers

### Feedback
- `GET /api/feedback` - Get all feedback
- `GET /api/feedback/:userPhone` - Get user feedback
- `POST /api/feedback` - Submit feedback

### Health Check
- `GET /health` - Server health check

---

## Security Concerns & Recommendations



## Environment Variables

### Backend (.env)
```env
PORT=3000
DB_HOST=94.249.213.97
DB_PORT=5432
DB_NAME=seniorcitizen
DB_USER=postgres
DB_PASSWORD=thane123
SUPABASE_URL=https://alcqejmotzojjbasrjol.supabase.co
SUPABASE_KEY=<JWT_TOKEN>
SUPABASE_PROJECT_ID=alcqejmotzojjbasrjol
CORS_ORIGIN=*
```

### Frontend (.env)
```env
API_URL=<Backend_API_URL>
```

---

## Version Information

### Application
- **App Name**: Snehaband (आधारवड ठाणे पोलीस)
- **Version**: `1.2.0` (Build 7)
- **Package Name**: `aadharwad`

### Backend
- **Name**: policemitra-backend
- **Version**: `1.0.0`

---

## Development Setup

### Frontend (Flutter)
```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Build for release
flutter build apk
flutter build ios
```

### Backend (Node.js)
```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Run in production mode
npm start
```

---

## Repository

- **Git Repository**: https://github.com/hellodeveloper7854/senior-citzen-app.git
- **Current Branch**: `development`
- **Main Branch**: `main`

---

*Last Updated: January 19, 2026*
