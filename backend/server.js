const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const multer = require('multer');
const { uploadAudioFile } = require('./services/supabaseService');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Configure multer for file uploads (stored in memory)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  },
});

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`\n[${timestamp}] ${req.method} ${req.path}`);
  if (Object.keys(req.body).length > 0) {
    console.log('Request Body:', JSON.stringify(req.body, null, 2));
  }
  if (Object.keys(req.params).length > 0) {
    console.log('Request Params:', req.params);
  }
  if (Object.keys(req.query).length > 0) {
    console.log('Request Query:', req.query);
  }

  // Log response
  const originalSend = res.send;
  res.send = function(data) {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] Response Status: ${res.statusCode}`);
    console.log('Response Data:', data);
    originalSend.call(this, data);
  };

  next();
});

// PostgreSQL Connection Pool
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test database connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    console.log('Health check requested');
    const client = await pool.connect();
    client.release();
    console.log('✅ Health check passed');
    res.json({ status: 'healthy', database: 'connected' });
  } catch (error) {
    console.error('❌ Health check failed:', error);
    res.status(500).json({ status: 'unhealthy', error: error.message });
  }
});

// ==================== AUTH ENDPOINTS ====================

// Login endpoint - validates email and password
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      console.log('❌ Login failed: Missing email or password');
      return res.status(400).json({ error: 'Email and password are required' });
    }

    console.log(`🔐 Login attempt for email: ${email}`);

    // Check if user exists in user_credentials table
    const credentialsResult = await pool.query(
      'SELECT * FROM user_credentials WHERE email = $1',
      [email]
    );

    if (credentialsResult.rows.length === 0) {
      console.log(`❌ Login failed: User not found with email: ${email}`);
      return res.status(404).json({ error: 'User not found' });
    }

    const credentials = credentialsResult.rows[0];

    // Verify password
    if (credentials.password !== password) {
      console.log(`❌ Login failed: Incorrect password for email: ${email}`);
      return res.status(401).json({ error: 'Incorrect password' });
    }

    // Get user profile from registrations table
    const userResult = await pool.query(
      'SELECT * FROM registrations WHERE contact_number = $1',
      [credentials.phone_number]
    );

    if (userResult.rows.length === 0) {
      console.log(`❌ Login failed: User profile not found for phone: ${credentials.phone_number}`);
      return res.status(404).json({ error: 'User profile not found' });
    }

    const user = userResult.rows[0];

    console.log(`✅ Login successful for: ${user.name} (${email})`);
    res.json({
      user: {
        email: credentials.email,
        phone_number: credentials.phone_number,
        name: user.name
      }
    });
  } catch (error) {
    console.error('❌ Error during login:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Create user credentials (for registration)
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, phone_number } = req.body;

    if (!email || !password || !phone_number) {
      console.log('❌ Registration failed: Missing required fields');
      return res.status(400).json({ error: 'Email, password, and phone number are required' });
    }

    console.log(`📝 Creating user credentials for: ${email}`);

    // Check if email already exists
    const existingEmail = await pool.query(
      'SELECT * FROM user_credentials WHERE email = $1',
      [email]
    );

    if (existingEmail.rows.length > 0) {
      console.log(`❌ Registration failed: Email already exists: ${email}`);
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Check if phone already exists
    const existingPhone = await pool.query(
      'SELECT * FROM user_credentials WHERE phone_number = $1',
      [phone_number]
    );

    if (existingPhone.rows.length > 0) {
      console.log(`❌ Registration failed: Phone already exists: ${phone_number}`);
      return res.status(409).json({ error: 'Phone number already registered' });
    }

    // Create user credentials
    const result = await pool.query(
      `INSERT INTO user_credentials (email, password, phone_number)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [email, password, phone_number]
    );

    console.log(`✅ User credentials created for: ${email}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error creating user credentials:', error);
    res.status(500).json({ error: 'Failed to create user credentials' });
  }
});

// ==================== USERS ENDPOINTS ====================

// Get all user registrations
app.get('/api/users', async (req, res) => {
  try {
    console.log('Fetching all users from database...');
    const result = await pool.query('SELECT * FROM registrations ORDER BY created_at DESC');
    console.log(`Successfully fetched ${result.rows.length} users`);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get single user by contact number
app.get('/api/users/:contactNumber', async (req, res) => {
  try {
    const { contactNumber } = req.params;
    console.log(`Fetching user with contact number: ${contactNumber}`);
    const result = await pool.query(
      'SELECT * FROM registrations WHERE contact_number = $1',
      [contactNumber]
    );
    if (result.rows.length === 0) {
      console.log(`User not found with contact number: ${contactNumber}`);
      return res.status(404).json({ error: 'User not found' });
    }
    console.log(`Successfully fetched user: ${result.rows[0].name}`);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Create new user registration
app.post('/api/users', async (req, res) => {
  try {
    const {
      full_name,
      date_of_birth,
      gender,
      aadhar_number,
      contact_number,
      marital_status,
      living_with,
      police_station,
      address,
      pincode,
      preferred_language,
      emergency_contact_1_name,
      emergency_contact_1_relation,
      emergency_contact_1_number,
      emergency_contact_2_name,
      emergency_contact_2_relation,
      emergency_contact_2_number,
      medical_conditions,
      other_medical_conditions,
      blood_group,
      profile_photo_url,
      profile_img,  // Frontend sends this field
      is_physically_disabled,
      disability_type
    } = req.body;

    // Use profile_img if profile_photo_url is not provided
    const finalProfilePhotoUrl = profile_photo_url || profile_img || null;

    console.log(`Creating new user registration for: ${full_name} (${contact_number})`);
    console.log(`Police Station: ${police_station}, Disabled: ${is_physically_disabled}`);

    // Handle medical_conditions - keep as array for PostgreSQL TEXT[] type
    const medicalConditionsArray = Array.isArray(medical_conditions)
      ? medical_conditions
      : (medical_conditions ? [medical_conditions] : []);

    const result = await pool.query(
      `INSERT INTO registrations (
        full_name, date_of_birth, gender, aadhar_number, contact_number,
        marital_status, living_with, police_station, address, pincode,
        preferred_language, emergency_contact_1_name, emergency_contact_1_relation,
        emergency_contact_1_number, emergency_contact_2_name, emergency_contact_2_relation,
        emergency_contact_2_number, medical_conditions, other_medical_conditions,
        blood_group, profile_photo_url, is_physically_disabled, disability_type, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24)
      RETURNING *`,
      [
        full_name,
        date_of_birth || null,
        gender || null,
        aadhar_number || null,
        contact_number,
        marital_status || null,
        living_with || null,
        police_station || null,
        address || null,
        pincode || null,
        preferred_language || null,
        emergency_contact_1_name || null,
        emergency_contact_1_relation || null,
        emergency_contact_1_number || null,
        emergency_contact_2_name || null,
        emergency_contact_2_relation || null,
        emergency_contact_2_number || null,
        medicalConditionsArray,  // Pass array directly for PostgreSQL TEXT[] type
        other_medical_conditions || null,
        blood_group || null,
        finalProfilePhotoUrl,
        is_physically_disabled || false,
        disability_type || null,
        'pending'  // Default status
      ]
    );

    console.log(`✅ Successfully created user with ID: ${result.rows[0].id}, Status: ${result.rows[0].status}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error creating user:', error);
    console.error('❌ Error details:', error.message);
    console.error('❌ Error code:', error.code);
    console.error('❌ Error constraint:', error.constraint);
    res.status(500).json({
      error: 'Failed to create user',
      details: error.message,
      code: error.code
    });
  }
});

// Update user
app.put('/api/users/:contactNumber', async (req, res) => {
  try {
    const { contactNumber } = req.params;
    const updates = req.body;

    // Build dynamic UPDATE query
    const setClause = Object.keys(updates)
      .map((key, index) => `${key} = $${index + 2}`)
      .join(', ');

    const values = [contactNumber, ...Object.values(updates)];

    const result = await pool.query(
      `UPDATE registrations SET ${setClause} WHERE contact_number = $1 RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// ==================== AUDIO RECORDINGS ENDPOINTS ====================

// Get all audio recordings
app.get('/api/recordings', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ar.*, r.full_name, r.contact_number
       FROM audio_recordings ar
       LEFT JOIN registrations r ON ar.user_phone = r.contact_number
       ORDER BY ar.recorded_at DESC`
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching recordings:', error);
    res.status(500).json({ error: 'Failed to fetch recordings' });
  }
});

// Get single recording
app.get('/api/recordings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT ar.*, r.full_name, r.contact_number
       FROM audio_recordings ar
       LEFT JOIN registrations r ON ar.user_phone = r.contact_number
       WHERE ar.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Recording not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching recording:', error);
    res.status(500).json({ error: 'Failed to fetch recording' });
  }
});

// Create new audio recording
app.post('/api/recordings', upload.single('audio'), async (req, res) => {
  try {
    const { user_phone, police_station } = req.body;
    const audioFile = req.file;

    console.log('🎙️ New audio recording received');
    console.log(`User Phone: ${user_phone}`);
    console.log(`Police Station: ${police_station}`);
    console.log(`Has audio file: ${!!audioFile}`);

    let audioUrl;

    if (audioFile) {
      // Upload file to Supabase
      const fileName = `recording_${Date.now()}.m4a`;
      audioUrl = await uploadAudioFile(audioFile.buffer, fileName, user_phone);
    } else if (req.body.audio_url) {
      // Use provided URL (for backward compatibility)
      audioUrl = req.body.audio_url;
    } else {
      console.log('❌ No audio file or URL provided');
      return res.status(400).json({ error: 'Audio file or URL is required' });
    }

    const result = await pool.query(
      `INSERT INTO audio_recordings (user_phone, audio_url, police_station, status)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [user_phone, audioUrl, police_station, 'pending']  // Explicitly set status to 'pending'
    );

    console.log(`✅ Audio recording created with ID: ${result.rows[0].id}, Status: ${result.rows[0].status}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error creating recording:', error);
    res.status(500).json({ error: 'Failed to create recording' });
  }
});

// Update recording status
app.patch('/api/recordings/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const result = await pool.query(
      'UPDATE audio_recordings SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Recording not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating recording status:', error);
    res.status(500).json({ error: 'Failed to update recording status' });
  }
});

// ==================== COMPLAINTS ENDPOINTS ====================

// Get all complaints
app.get('/api/complaints', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT c.*, r.full_name, r.contact_number
       FROM complaints c
       LEFT JOIN registrations r ON c.user_phone = r.contact_number
       ORDER BY c.submitted_at DESC`
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching complaints:', error);
    res.status(500).json({ error: 'Failed to fetch complaints' });
  }
});

// Get single complaint
app.get('/api/complaints/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT c.*, r.full_name, r.contact_number
       FROM complaints c
       LEFT JOIN registrations r ON c.user_phone = r.contact_number
       WHERE c.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Complaint not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching complaint:', error);
    res.status(500).json({ error: 'Failed to fetch complaint' });
  }
});

// Create new complaint
app.post('/api/complaints', async (req, res) => {
  try {
    const {
      user_phone,
      title,
      description,
      police_station,
      incident_date,
      incident_time,
      location
    } = req.body;

    console.log('📝 New complaint registered');
    console.log(`User Phone: ${user_phone} (type: ${typeof user_phone}), Title: ${title}`);
    console.log(`Police Station: ${police_station}, Location: ${location}`);
    console.log(`Incident Date: ${incident_date} (type: ${typeof incident_date}), Time: ${incident_time}`);

    // Validate required fields
    if (!user_phone || !title || !description) {
      console.log('❌ Missing required fields');
      return res.status(400).json({ error: 'user_phone, title, and description are required' });
    }

    // Prepare values - handle nulls and convert types
    const values = [
      String(user_phone),  // Ensure phone is string
      title,
      description,
      police_station || null,
      incident_date || null,
      incident_time || null,
      location || null,
      'pending'  // Default status
    ];

    console.log('📊 Insert values:', values);

    const result = await pool.query(
      `INSERT INTO complaints (
        user_phone, title, description, police_station,
        incident_date, incident_time, location, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      values
    );

    console.log(`✅ Complaint created with ID: ${result.rows[0].id}, Status: ${result.rows[0].status}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error creating complaint:', error);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error code:', error.code);
    console.error('❌ Error constraint:', error.constraint);
    console.error('❌ Error detail:', error.detail);
    res.status(500).json({
      error: 'Failed to create complaint',
      details: error.message,
      code: error.code
    });
  }
});

// Update complaint status
app.patch('/api/complaints/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, admin_notes } = req.body;

    const result = await pool.query(
      'UPDATE complaints SET status = $1, admin_notes = $2 WHERE id = $3 RETURNING *',
      [status, admin_notes, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Complaint not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating complaint status:', error);
    res.status(500).json({ error: 'Failed to update complaint status' });
  }
});

// ==================== SOS ALERTS ENDPOINTS ====================

// Get all SOS alerts
app.get('/api/sos-alerts', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM sos_alerts ORDER BY alert_timestamp DESC'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching SOS alerts:', error);
    res.status(500).json({ error: 'Failed to fetch SOS alerts' });
  }
});

// Get single SOS alert
app.get('/api/sos-alerts/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM sos_alerts WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'SOS alert not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching SOS alert:', error);
    res.status(500).json({ error: 'Failed to fetch SOS alert' });
  }
});

// Create new SOS alert
app.post('/api/sos-alerts', async (req, res) => {
  const client = await pool.connect();
  try {
    const {
      user_id,
      user_name,
      latitude,
      longitude,
      location_address,
      police_station,
      emergency_contacts
    } = req.body;

    console.log('🚨 SOS ALERT RECEIVED!');
    console.log(`User: ${user_name} (ID: ${user_id})`);
    console.log(`Location: ${latitude}, ${longitude}`);
    console.log(`Address: ${location_address}`);
    console.log(`Police Station: ${police_station}`);
    console.log(`Emergency Contacts: ${JSON.stringify(emergency_contacts)}`);

    // Handle emergency_contacts - ensure it's an array
    const contactsArray = Array.isArray(emergency_contacts) ? emergency_contacts : [];

    await client.query('BEGIN');

    // Fix sequence if needed (in case it's out of sync)
    await client.query(`
      SELECT setval(
        pg_get_serial_sequence('sos_alerts', 'id'),
        COALESCE((SELECT MAX(id) FROM sos_alerts), 0) + 1,
        false
      )
    `);

    const result = await client.query(
      `INSERT INTO sos_alerts (
        user_id, user_name, latitude, longitude,
        location_address, police_station, emergency_contacts, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        user_id,
        user_name,
        latitude,
        longitude,
        location_address,
        police_station,
        contactsArray,  // Pass array directly for PostgreSQL TEXT[] type
        'active'  // Explicitly set status to 'active'
      ]
    );

    await client.query('COMMIT');

    console.log(`✅ SOS Alert created with ID: ${result.rows[0].id}, Status: ${result.rows[0].status}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error creating SOS alert:', error);
    console.error('❌ Error details:', error.message);
    console.error('❌ Error code:', error.code);
    res.status(500).json({ error: 'Failed to create SOS alert', details: error.message });
  } finally {
    client.release();
  }
});

// Update SOS alert status
app.patch('/api/sos-alerts/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolved_by, notes } = req.body;

    console.log(`🔄 Updating SOS Alert ID: ${id} to status: ${status}`);
    console.log(`Resolved by: ${resolved_by}, Notes: ${notes}`);

    const updateData = {
      status,
      resolved_by,
      notes
    };

    if (status !== 'active') {
      updateData.resolved_at = new Date().toISOString();
    }

    const result = await pool.query(
      `UPDATE sos_alerts
       SET status = $1, resolved_by = $2, notes = $3, resolved_at = $4
       WHERE id = $5
       RETURNING *`,
      [updateData.status, updateData.resolved_by, updateData.notes, updateData.resolved_at, id]
    );

    if (result.rows.length === 0) {
      console.log(`❌ SOS Alert not found with ID: ${id}`);
      return res.status(404).json({ error: 'SOS alert not found' });
    }

    console.log(`✅ Successfully updated SOS Alert ID: ${id}`);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error updating SOS alert status:', error);
    res.status(500).json({ error: 'Failed to update SOS alert status' });
  }
});

// Get active SOS alerts count
app.get('/api/sos-alerts/active/count', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT COUNT(*) FROM sos_alerts WHERE status = $1',
      ['active']
    );
    res.json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    console.error('Error fetching active SOS count:', error);
    res.status(500).json({ error: 'Failed to fetch active SOS count' });
  }
});

// ==================== HOSPITAL CONTACTS ENDPOINTS ====================

// Get all hospital contacts
app.get('/api/hospital-contacts', async (req, res) => {
  try {
    console.log('🏥 Fetching hospital contacts from database...');
    const result = await pool.query(
      'SELECT * FROM hospital_contacts WHERE is_active = TRUE ORDER BY display_order ASC'
    );
    console.log(`✅ Successfully fetched ${result.rows.length} hospital contacts`);
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Error fetching hospital contacts:', error);
    res.status(500).json({ error: 'Failed to fetch hospital contacts' });
  }
});

// ==================== NATIONAL HELPLINE ENDPOINTS ====================

// Get all national helplines
app.get('/api/national-helplines', async (req, res) => {
  try {
    console.log('📞 Fetching national helplines from database...');
    const result = await pool.query(
      'SELECT * FROM national_helpline WHERE is_active = TRUE ORDER BY display_order ASC'
    );
    console.log(`✅ Successfully fetched ${result.rows.length} national helplines`);
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Error fetching national helplines:', error);
    res.status(500).json({ error: 'Failed to fetch national helplines' });
  }
});

// ==================== USER FEEDBACK ENDPOINTS ====================

// Get all feedback
app.get('/api/feedback', async (req, res) => {
  try {
    console.log('📝 Fetching all feedback from database...');
    const result = await pool.query(
      `SELECT f.*, r.full_name, r.contact_number
       FROM user_feedback f
       LEFT JOIN registrations r ON f.user_phone = r.contact_number
       ORDER BY f.created_at DESC`
    );
    console.log(`✅ Successfully fetched ${result.rows.length} feedback entries`);
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Error fetching feedback:', error);
    res.status(500).json({ error: 'Failed to fetch feedback' });
  }
});

// Get feedback for a specific user
app.get('/api/feedback/:userPhone', async (req, res) => {
  try {
    const { userPhone } = req.params;
    console.log(`📝 Fetching feedback for user: ${userPhone}`);
    const result = await pool.query(
      'SELECT * FROM user_feedback WHERE user_phone = $1 ORDER BY created_at DESC',
      [userPhone]
    );
    console.log(`✅ Successfully fetched ${result.rows.length} feedback entries`);
    res.json(result.rows);
  } catch (error) {
    console.error('❌ Error fetching user feedback:', error);
    res.status(500).json({ error: 'Failed to fetch user feedback' });
  }
});

// Submit new feedback
app.post('/api/feedback', async (req, res) => {
  try {
    const { user_phone, rating, feedback } = req.body;

    console.log('📝 New feedback received');
    console.log(`User Phone: ${user_phone}, Rating: ${rating}`);
    console.log(`Feedback: ${feedback}`);

    // Validate input
    if (!user_phone || !rating || !feedback) {
      console.log('❌ Feedback submission failed: Missing required fields');
      return res.status(400).json({ error: 'user_phone, rating, and feedback are required' });
    }

    // Validate rating range
    if (rating < 1 || rating > 5) {
      console.log('❌ Feedback submission failed: Invalid rating');
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    const result = await pool.query(
      `INSERT INTO user_feedback (user_phone, rating, feedback)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [user_phone, rating, feedback]
    );

    console.log(`✅ Feedback created with ID: ${result.rows[0].id}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('❌ Error creating feedback:', error);
    res.status(500).json({ error: 'Failed to create feedback' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Unhandled error:', err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log('\n=================================');
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📡 Listening on 0.0.0.0:${PORT}`);
  console.log(`🗄️  Database: ${process.env.DB_NAME}@${process.env.DB_HOST}:${process.env.DB_PORT}`);
  console.log('=================================\n');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\nShutting down gracefully...');
  await pool.end();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\nShutting down gracefully...');
  await pool.end();
  process.exit(0);
});
