const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client with hardcoded credentials
const supabaseUrl = 'https://alcqejmotzojjbasrjol.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFsY3Flam1vdHpvampiYXNyam9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwMzg3MDYsImV4cCI6MjA3NDYxNDcwNn0.9h22kaBiPksRsyGTwhPjzT5VAxYaSQ-z52r8KOJlAuY';

console.log('✅ Supabase client initialized');
console.log(`🔗 Supabase URL: ${supabaseUrl}`);
console.log(`📦 Project ID: alcqejmotzojjbasrjol`);

const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Upload audio file to Supabase Storage
 * @param {Buffer} fileBuffer - The file buffer
 * @param {string} fileName - The name of the file
 * @param {string} phoneNumber - User's phone number for folder structure
 * @returns {Promise<string>} - Public URL of the uploaded file
 */
async function uploadAudioFile(fileBuffer, fileName, phoneNumber) {
  try {
    console.log('📤 Uploading audio file to Supabase...');
    console.log(`File: ${fileName}, User: ${phoneNumber}`);

    // Create folder path: audio-recordings/{phone_number}/{filename}
    const filePath = `audio-recordings/${phoneNumber}/${fileName}`;

    // Upload file to Supabase Storage
    const { data, error } = await supabase.storage
      .from('audio-recordings')
      .upload(filePath, fileBuffer, {
        contentType: 'audio/m4a',
        upsert: true,
      });

    if (error) {
      console.error('❌ Supabase upload error:', error);
      throw error;
    }

    console.log('✅ File uploaded successfully to Supabase:', data.path);

    // Get public URL
    const { data: publicUrlData } = supabase.storage
      .from('audio-recordings')
      .getPublicUrl(filePath);

    const publicUrl = publicUrlData.publicUrl;
    console.log('✅ Public URL generated:', publicUrl);

    return publicUrl;
  } catch (error) {
    console.error('❌ Error uploading to Supabase:', error);
    throw error;
  }
}

/**
 * Delete audio file from Supabase Storage
 * @param {string} filePath - The file path in storage
 * @returns {Promise<boolean>}
 */
async function deleteAudioFile(filePath) {
  try {
    console.log('🗑️ Deleting audio file from Supabase:', filePath);

    const { error } = await supabase.storage
      .from('audio-recordings')
      .remove([filePath]);

    if (error) {
      console.error('❌ Supabase delete error:', error);
      throw error;
    }

    console.log('✅ File deleted successfully from Supabase');
    return true;
  } catch (error) {
    console.error('❌ Error deleting from Supabase:', error);
    throw error;
  }
}

module.exports = {
  uploadAudioFile,
  deleteAudioFile,
};
