// Admin Panel React JS Code for Decrypting and Displaying Contact Numbers
// Uses AES-CBC with fixed key and IV, matching the Flutter app.

import React, { useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';
import CryptoJS from 'crypto-js';

const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
const supabase = createClient(supabaseUrl, supabaseKey);

const KEY = CryptoJS.enc.Utf8.parse('ThaneMitrSecretKey1234567890abcd'); // 32 bytes
const IV = CryptoJS.enc.Utf8.parse('VectorInit123456'); // 16 bytes

function decryptText(cipherBase64) {
  if (!cipherBase64) return cipherBase64;
  try {
    if (!isProbablyBase64(cipherBase64)) return cipherBase64;
    const decrypted = CryptoJS.AES.decrypt(
      { ciphertext: CryptoJS.enc.Base64.parse(cipherBase64) },
      KEY,
      { iv: IV, mode: CryptoJS.mode.CBC, padding: CryptoJS.pad.Pkcs7 }
    );
    const plain = decrypted.toString(CryptoJS.enc.Utf8);
    return plain || cipherBase64;
  } catch (error) {
    return cipherBase64;
  }
}

function isProbablyBase64(s) {
  return /^[A-Za-z0-9+/=]+$/.test(s) && s.length % 4 === 0;
}

function AdminPanel() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    const { data, error } = await supabase.from('registrations').select('*');
    if (error) {
      console.error(error);
      return;
    }

    // Decrypt sensitive fields
    const decryptedUsers = data.map((user) => ({
      ...user,
      aadhar_number: decryptText(user.aadhar_number),
      emergency_contact_1_number: decryptText(user.emergency_contact_1_number),
      emergency_contact_2_number: decryptText(user.emergency_contact_2_number),
    }));

    setUsers(decryptedUsers);
    setLoading(false);
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      <h1>Admin Panel - User Registrations</h1>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Contact Number</th>
            <th>Aadhaar Number</th>
            <th>Emergency Contact 1</th>
            <th>Emergency Contact 2</th>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => (
            <tr key={user.contact_number}>
              <td>{user.name}</td>
              <td>{user.contact_number}</td>
              <td>{user.aadhar_number}</td>
              <td>{user.emergency_contact_1_name} - {user.emergency_contact_1_number}</td>
              <td>{user.emergency_contact_2_name} - {user.emergency_contact_2_number}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default AdminPanel;