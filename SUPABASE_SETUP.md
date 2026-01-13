# Supabase Voice Recording Upload Setup

## Overview
This document provides instructions for setting up Supabase storage to handle voice recording uploads for the Snehaband application.

## Supabase Configuration

### 1. Create Supabase Storage Bucket

1. Log in to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `alcqejmotzojjbasrjol`
3. Navigate to **Storage** from the left sidebar
4. Click **"New Bucket"**
5. Create a bucket with the following settings:
   - **Name**: `audio-recordings`
   - **Public bucket**: OFF (for security)
   - **File size limit**: 50 MB
   - **Allowed MIME types**: `audio/m4a`, `audio/mp4`, `audio/mpeg`

### 2. Configure Bucket Policies

To allow your backend to upload files, you need to set up storage policies:

1. In the Supabase Dashboard, go to **Storage** > **audio-recordings**
2. Click on **Policies** tab
3. Add the following policies:

#### Policy for Uploading (Service Role)

```sql
-- Allow uploads from service role (backend)
CREATE POLICY "Allow service role uploads"
ON storage.objects
FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'audio-recordings');

-- Allow service role to read all files
CREATE POLICY "Allow service role read"
ON storage.objects
FOR SELECT
TO service_role
USING (bucket_id = 'audio-recordings');

-- Allow service role to delete files
CREATE POLICY "Allow service role delete"
ON storage.objects
FOR DELETE
TO service_role
USING (bucket_id = 'audio-recordings');
```

#### Policy for Public Read Access (Optional)

If you want audio files to be publicly accessible:

```sql
-- Allow public read access to audio recordings
CREATE POLICY "Allow public read access"
ON storage.objects
FOR SELECT
TO anon
USING (bucket_id = 'audio-recordings');
```

### 3. Enable Public URLs (Optional)

If you want the audio files to be publicly accessible:

1. Go to **Storage** > **audio-recordings**
2. Click on **Configuration** tab
3. Toggle **"Public Bucket"** to ON
4. This will generate public URLs in the format:
   ```
   https://alcqejmotzojjbasrjol.supabase.co/storage/v1/object/public/audio-recordings/{phone_number}/{filename}
   ```

## Backend Configuration

### 1. Environment Variables

The backend `.env` file already contains the necessary Supabase credentials:

```env
SUPABASE_URL=https://alcqejmotzojjbasrjol.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFsY3Flam1vdHpvampiYXNyam9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwMzg3MDYsImV4cCI6MjA3NDYxNDcwNn0.9h22kaBiPksRsyGTwhPjzT5VAxYaSQ-z52r8KOJlAuY
SUPABASE_PROJECT_ID=alcqejmotzojjbasrjol
```

### 2. Backend Files Modified

- **backend/services/supabaseService.js**: Handles file uploads to Supabase
- **backend/server.js**: Updated to accept multipart file uploads
- **backend/package.json**: Added Supabase and multer dependencies

### 3. Install Dependencies

```bash
cd backend
npm install
```

### 4. Start the Backend Server

```bash
cd backend
npm start
```

The backend server will now:
1. Accept audio file uploads from the Flutter app
2. Upload them to Supabase Storage
3. Store the metadata (including Supabase URL) in PostgreSQL database

## Flutter App Configuration

### 1. Install Dependencies

The Flutter app needs the `http_parser` package for multipart requests:

```bash
flutter pub get
```

### 2. Files Modified

- **lib/services/api_service.dart**: Updated `uploadAudioRecording()` method to upload files
- **lib/screens/record_screen.dart**: Simplified to call the updated upload method

## File Structure in Supabase

Uploaded files will be organized in Supabase Storage as follows:

```
audio-recordings/
├── {phone_number_1}/
│   ├── recording_1234567890.m4a
│   ├── recording_1234567891.m4a
│   └── ...
├── {phone_number_2}/
│   ├── recording_1234567892.m4a
│   └── ...
└── ...
```

## Database Schema

The PostgreSQL database stores the metadata in the `audio_recordings` table:

```sql
CREATE TABLE audio_recordings (
  id SERIAL PRIMARY KEY,
  user_phone VARCHAR(20) NOT NULL,
  police_station VARCHAR(255),
  audio_url TEXT NOT NULL,        -- Supabase public URL
  recorded_at TIMESTAMP NOT NULL,
  duration INTEGER,                -- Duration in seconds (optional)
  status VARCHAR(20) DEFAULT 'pending',
  admin_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Testing the Upload

### 1. Test Backend Endpoint Directly

```bash
curl -X POST http://localhost:3000/api/recordings \
  -F "audio=@/path/to/test.m4a" \
  -F "user_phone=1234567890" \
  -F "police_station=Test Station"
```

### 2. Test from Flutter App

1. Run the Flutter app
2. Navigate to **Record Complaints**
3. Tap the microphone button to start recording
4. Tap again to stop recording
5. Choose **Upload** when prompted
6. Check the console logs for upload progress
7. Navigate to **Check Recording Status** to verify the upload

## Troubleshooting

### Issue: "Bucket not found" Error

**Solution**: Ensure you've created the `audio-recordings` bucket in Supabase Dashboard.

### Issue: "Permission denied" Error

**Solution**: Check that storage policies are correctly configured in Supabase Dashboard.

### Issue: Files not publicly accessible

**Solution**: Either enable public bucket access or use signed URLs. For signed URLs, modify the `supabaseService.js` to generate signed URLs instead of public URLs.

### Issue: File size limit exceeded

**Solution**: Increase the file size limit in both:
- Backend server.js: `limits: { fileSize: 50 * 1024 * 1024 }`
- Supabase Bucket settings

### Issue: CORS errors

**Solution**: Ensure CORS is properly configured in backend:
```env
CORS_ORIGIN=*
```

## Security Considerations

1. **Keep bucket private** by default to prevent unauthorized access
2. **Use signed URLs** for temporary access if needed
3. **Validate file types** on the backend before uploading
4. **Set reasonable file size limits** to prevent abuse
5. **Regular cleanup** of old recordings from storage
6. **Monitor storage usage** in Supabase Dashboard

## Monitoring

Check the Supabase Dashboard regularly:

1. **Storage Usage**: Monitor storage consumption
2. **API Requests**: Check for any unusual activity
3. **Logs**: Review error logs in the Supabase Dashboard

## Cost Optimization

Supabase offers generous free tier limits:

- **Storage**: 1 GB free
- **Bandwidth**: 2 GB free per month

For production:
- Implement automatic cleanup of old recordings
- Use compression for audio files
- Consider CDN for better performance
- Monitor and set up alerts for usage

## Next Steps

1. ✅ Create Supabase storage bucket
2. ✅ Configure storage policies
3. ✅ Test file upload from Flutter app
4. ⏳ Implement recording playback functionality
5. ⏳ Add admin interface for managing recordings
6. ⏳ Set up automated cleanup jobs

## Contact

For issues or questions, refer to:
- Supabase Documentation: https://supabase.com/docs
- Supabase Storage Guide: https://supabase.com/docs/guides/storage
