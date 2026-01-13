# Police Mitra Backend API

Node.js backend server with PostgreSQL connection for the Police Mitra application.

## Features

- Direct PostgreSQL connection (no Supabase dependency)
- RESTful API endpoints for all operations
- User registration management
- Audio recordings tracking
- Complaint management system
- SOS emergency alerts
- Health check endpoint
- Graceful shutdown handling

## Prerequisites

- Node.js (>= 16.0.0)
- PostgreSQL database server
- npm or yarn package manager

## Database Configuration

The backend connects to a PostgreSQL database with these credentials:
- Host: 94.249.213.97
- Port: 5432
- Database: policemitra
- User: postgres
- Password: thane123

**Important:** Make sure your PostgreSQL server allows remote connections from your backend server's IP address.

## Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. The `.env` file is already configured with your database credentials. If you need to modify it:

```env
PORT=3000
DB_HOST=94.249.213.97
DB_PORT=5432
DB_NAME=policemitra
DB_USER=postgres
DB_PASSWORD=thane123
CORS_ORIGIN=*
```

## Database Tables Required

The following tables should exist in your PostgreSQL database:

1. **registrations** - User registrations
2. **audio_recordings** - Audio recordings from users
3. **complaints** - User complaints
4. **sos_alerts** - SOS emergency alerts

## Running the Server

### Development Mode (with auto-restart)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will start on port 3000 (or the port specified in your `.env` file).

## API Endpoints

### Health Check
- `GET /health` - Check server and database connectivity

### Users
- `GET /api/users` - Get all user registrations
- `GET /api/users/:contactNumber` - Get specific user by contact number
- `POST /api/users` - Create new user registration
- `PUT /api/users/:contactNumber` - Update user details

### Audio Recordings
- `GET /api/recordings` - Get all audio recordings (with user details)
- `GET /api/recordings/:id` - Get specific recording
- `POST /api/recordings` - Create new audio recording
- `PATCH /api/recordings/:id/status` - Update recording status

### Complaints
- `GET /api/complaints` - Get all complaints (with user details)
- `GET /api/complaints/:id` - Get specific complaint
- `POST /api/complaints` - Create new complaint
- `PATCH /api/complaints/:id/status` - Update complaint status and add admin notes

### SOS Alerts
- `GET /api/sos-alerts` - Get all SOS alerts
- `GET /api/sos-alerts/:id` - Get specific SOS alert
- `POST /api/sos-alerts` - Create new SOS alert
- `PATCH /api/sos-alerts/:id/status` - Update SOS alert status
- `GET /api/sos-alerts/active/count` - Get count of active alerts

## Example API Calls

### Get all users
```bash
curl http://localhost:3000/api/users
```

### Create a new user
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "contact_number": "1234567890",
    "aadhar_number": "encrypted_aadhar",
    "emergency_contact_1_name": "Jane Doe",
    "emergency_contact_1_number": "encrypted_number",
    "police_station": "Station 1"
  }'
```

### Update recording status
```bash
curl -X PATCH http://localhost:3000/api/recordings/1/status \
  -H "Content-Type: application/json" \
  -d '{"status": "reviewed"}'
```

### Create SOS alert
```bash
curl -X POST http://localhost:3000/api/sos-alerts \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "1234567890",
    "user_name": "John Doe",
    "latitude": 19.0760,
    "longitude": 72.8777,
    "location_address": "Mumbai, Maharashtra",
    "police_station": "Station 1",
    "emergency_contacts": ["9876543210", "9876543211"]
  }'
```

## Admin Panel Configuration

The admin panel (`admin_panel.js`) has been updated to use this new backend API.

To configure the API URL in the admin panel:

1. Create a `.env` file in the root directory (where admin_panel.js is located)
2. Add the API URL:
```env
REACT_APP_API_URL=http://localhost:3000/api
```

For production, replace `localhost` with your actual server URL:
```env
REACT_APP_API_URL=https://your-backend-server.com/api
```

## Migration from Supabase

The migration is complete! Here's what changed:

**Removed:**
- Supabase SDK dependency
- Supabase client initialization
- Supabase-specific query syntax

**Added:**
- Direct PostgreSQL connection using `pg` library
- RESTful API endpoints
- Connection pooling for better performance
- Environment-based configuration

**Admin Panel Changes:**
- Removed `@supabase/supabase-js` import
- Added `fetch` API calls to backend endpoints
- All CRUD operations now use the new backend API

## Security Considerations

1. **Environment Variables**: Never commit `.env` files to version control
2. **Database Password**: Use strong passwords and change regularly
3. **CORS**: Configure `CORS_ORIGIN` in `.env` to allow only trusted domains
4. **Input Validation**: Add input validation for production use
5. **Rate Limiting**: Consider adding rate limiting for API endpoints
6. **Authentication**: Add authentication/authorization middleware for production
7. **HTTPS**: Use HTTPS in production for secure data transmission

## Production Deployment

For production deployment, consider:

1. **Process Manager**: Use PM2 to keep the server running:
```bash
npm install -g pm2
pm2 start server.js --name policemitra-backend
pm2 startup
pm2 save
```

2. **Reverse Proxy**: Use Nginx or Apache as a reverse proxy
3. **SSL Certificate**: Install SSL certificate for HTTPS
4. **Firewall**: Configure firewall to allow only necessary ports
5. **Monitoring**: Set up logging and monitoring

## Troubleshooting

### Connection Refused
- Check if PostgreSQL server is running
- Verify database credentials in `.env`
- Ensure database allows remote connections

### Port Already in Use
- Change the `PORT` in `.env` file
- Or kill the process using port 3000

### CORS Errors
- Update `CORS_ORIGIN` in `.env` with your frontend URL
- For development, you can use `*` to allow all origins

## Support

For issues or questions, please contact the development team.
