// Admin Panel React JS Code for Decrypting and Displaying Contact Numbers
// Uses AES-CBC with fixed key and IV, matching the Flutter app.

import React, { useState, useEffect } from 'react';
import CryptoJS from 'crypto-js';

// Backend API Configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api';

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
  const [recordings, setRecordings] = useState([]);
  const [complaints, setComplaints] = useState([]);
  const [sosAlerts, setSosAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('users');

  useEffect(() => {
    if (activeTab === 'users') {
      fetchUsers();
    } else if (activeTab === 'recordings') {
      fetchRecordings();
    } else if (activeTab === 'complaints') {
      fetchComplaints();
    } else if (activeTab === 'sos') {
      fetchSOSAlerts();
    }
  }, [activeTab]);

  const fetchUsers = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/users`);
      if (!response.ok) throw new Error('Failed to fetch users');
      const data = await response.json();

      // Decrypt sensitive fields
      const decryptedUsers = data.map((user) => ({
        ...user,
        aadhar_number: decryptText(user.aadhar_number),
        emergency_contact_1_number: decryptText(user.emergency_contact_1_number),
        emergency_contact_2_number: decryptText(user.emergency_contact_2_number),
      }));

      setUsers(decryptedUsers);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching users:', error);
      setLoading(false);
    }
  };

  const fetchRecordings = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/recordings`);
      if (!response.ok) throw new Error('Failed to fetch recordings');
      const data = await response.json();

      setRecordings(data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching recordings:', error);
      setLoading(false);
    }
  };

  const fetchComplaints = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/complaints`);
      if (!response.ok) throw new Error('Failed to fetch complaints');
      const data = await response.json();

      setComplaints(data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching complaints:', error);
      setLoading(false);
    }
  };

  const fetchSOSAlerts = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/sos-alerts`);
      if (!response.ok) throw new Error('Failed to fetch SOS alerts');
      const data = await response.json();

      setSosAlerts(data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching SOS alerts:', error);
      setLoading(false);
    }
  };

  const updateRecordingStatus = async (recordingId, status) => {
    try {
      const response = await fetch(`${API_BASE_URL}/recordings/${recordingId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status }),
      });

      if (!response.ok) throw new Error('Failed to update recording status');

      // Refresh recordings
      fetchRecordings();
    } catch (error) {
      console.error('Error updating recording status:', error);
    }
  };

  const updateComplaintStatus = async (complaintId, status, adminNotes = '') => {
    try {
      const response = await fetch(`${API_BASE_URL}/complaints/${complaintId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status, admin_notes: adminNotes }),
      });

      if (!response.ok) throw new Error('Failed to update complaint status');

      // Refresh complaints
      fetchComplaints();
    } catch (error) {
      console.error('Error updating complaint status:', error);
    }
  };

  const updateSOSAlertStatus = async (alertId, status, resolvedBy = '', notes = '') => {
    try {
      const response = await fetch(`${API_BASE_URL}/sos-alerts/${alertId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          status,
          resolved_by: resolvedBy,
          notes
        }),
      });

      if (!response.ok) throw new Error('Failed to update SOS alert status');

      // Refresh SOS alerts
      fetchSOSAlerts();
    } catch (error) {
      console.error('Error updating SOS alert status:', error);
    }
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString();
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>Admin Panel - Aadharwad</h1>

      {/* Tab Navigation */}
      <div style={{ marginBottom: '20px' }}>
        <button
          onClick={() => setActiveTab('users')}
          style={{
            padding: '10px 20px',
            marginRight: '10px',
            backgroundColor: activeTab === 'users' ? '#3E0FAD' : '#f0f0f0',
            color: activeTab === 'users' ? 'white' : 'black',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer'
          }}
        >
          User Registrations
        </button>
        <button
          onClick={() => setActiveTab('recordings')}
          style={{
            padding: '10px 20px',
            marginRight: '10px',
            backgroundColor: activeTab === 'recordings' ? '#3E0FAD' : '#f0f0f0',
            color: activeTab === 'recordings' ? 'white' : 'black',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer'
          }}
        >
          Audio Recordings ({recordings.length})
        </button>
        <button
          onClick={() => setActiveTab('complaints')}
          style={{
            padding: '10px 20px',
            marginRight: '10px',
            backgroundColor: activeTab === 'complaints' ? '#3E0FAD' : '#f0f0f0',
            color: activeTab === 'complaints' ? 'white' : 'black',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer'
          }}
        >
          Complaints ({complaints.length})
        </button>
        <button
          onClick={() => setActiveTab('sos')}
          style={{
            padding: '10px 20px',
            backgroundColor: activeTab === 'sos' ? '#dc2626' : '#f0f0f0',
            color: activeTab === 'sos' ? 'white' : 'black',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer'
          }}
        >
          SOS Alerts ({sosAlerts.filter(alert => alert.status === 'active').length})
        </button>
      </div>

      {activeTab === 'users' && (
        <div>
          <h2>User Registrations</h2>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ backgroundColor: '#f5f5f5' }}>
                <th style={{ padding: '10px', border: '1px solid #ddd' }}>Name</th>
                <th style={{ padding: '10px', border: '1px solid #ddd' }}>Contact Number</th>
                <th style={{ padding: '10px', border: '1px solid #ddd' }}>Aadhaar Number</th>
                <th style={{ padding: '10px', border: '1px solid #ddd' }}>Emergency Contact 1</th>
                <th style={{ padding: '10px', border: '1px solid #ddd' }}>Emergency Contact 2</th>
                <th style={{ padding: '10px', border: '1px solid #ddd' }}>Physical Disability</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.contact_number}>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>{user.name}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>{user.contact_number}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>{user.aadhar_number}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>{user.emergency_contact_1_name} - {user.emergency_contact_1_number}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>{user.emergency_contact_2_name} - {user.emergency_contact_2_number}</td>
                  <td style={{ padding: '10px', border: '1px solid #ddd' }}>
                    {user.is_physically_disabled ? `Yes - ${user.disability_type || 'Type not specified'}` : 'No'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {activeTab === 'recordings' && (
        <div>
          <h2>Audio Recordings</h2>
          <div style={{ display: 'grid', gap: '20px' }}>
            {recordings.map((recording) => (
              <div key={recording.id} style={{
                border: '1px solid #ddd',
                borderRadius: '10px',
                padding: '20px',
                backgroundColor: '#fafafa'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                  <h3>{recording.registrations?.full_name || 'Unknown User'}</h3>
                  <span style={{
                    padding: '5px 10px',
                    borderRadius: '15px',
                    fontSize: '12px',
                    backgroundColor: recording.status === 'pending' ? '#fef3c7' : recording.status === 'reviewed' ? '#d1fae5' : '#e5e7eb',
                    color: recording.status === 'pending' ? '#92400e' : recording.status === 'reviewed' ? '#065f46' : '#374151'
                  }}>
                    {recording.status}
                  </span>
                </div>

                <p><strong>Phone:</strong> {recording.user_phone}</p>
                <p><strong>Police Station:</strong> {recording.police_station || 'Not specified'}</p>
                <p><strong>Recorded At:</strong> {formatDate(recording.recorded_at)}</p>

                <div style={{ marginTop: '15px' }}>
                  <audio controls style={{ width: '100%' }}>
                    <source src={recording.audio_url} type="audio/m4a" />
                    Your browser does not support the audio element.
                  </audio>
                </div>

                <div style={{ marginTop: '15px', display: 'flex', gap: '10px' }}>
                  {recording.status !== 'reviewed' && (
                    <button
                      onClick={() => updateRecordingStatus(recording.id, 'reviewed')}
                      style={{
                        padding: '8px 16px',
                        backgroundColor: '#10b981',
                        color: 'white',
                        border: 'none',
                        borderRadius: '5px',
                        cursor: 'pointer'
                      }}
                    >
                      Mark as Reviewed
                    </button>
                  )}
                  {recording.status !== 'archived' && (
                    <button
                      onClick={() => updateRecordingStatus(recording.id, 'archived')}
                      style={{
                        padding: '8px 16px',
                        backgroundColor: '#6b7280',
                        color: 'white',
                        border: 'none',
                        borderRadius: '5px',
                        cursor: 'pointer'
                      }}
                    >
                      Archive
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'complaints' && (
        <div>
          <h2>Complaints</h2>
          <div style={{ display: 'grid', gap: '20px' }}>
            {complaints.map((complaint) => (
              <div key={complaint.id} style={{
                border: '1px solid #ddd',
                borderRadius: '10px',
                padding: '20px',
                backgroundColor: '#fafafa'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                  <h3>{complaint.registrations?.full_name || 'Unknown User'}</h3>
                  <span style={{
                    padding: '5px 10px',
                    borderRadius: '15px',
                    fontSize: '12px',
                    backgroundColor: complaint.status === 'pending' ? '#fef3c7' : complaint.status === 'under_review' ? '#dbeafe' : complaint.status === 'resolved' ? '#d1fae5' : '#fee2e2',
                    color: complaint.status === 'pending' ? '#92400e' : complaint.status === 'under_review' ? '#1e40af' : complaint.status === 'resolved' ? '#065f46' : '#991b1b'
                  }}>
                    {complaint.status.replace('_', ' ').toUpperCase()}
                  </span>
                </div>

                <div style={{ marginBottom: '15px' }}>
                  <h4 style={{ margin: '0 0 10px 0', color: '#374151' }}>{complaint.title}</h4>
                  <p style={{ margin: '0 0 10px 0', lineHeight: '1.5', color: '#4b5563' }}>{complaint.description}</p>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '15px' }}>
                  <div>
                    <strong>Phone:</strong> {complaint.user_phone}
                  </div>
                  <div>
                    <strong>Police Station:</strong> {complaint.police_station || 'Not specified'}
                  </div>
                  <div>
                    <strong>Submitted:</strong> {formatDate(complaint.submitted_at)}
                  </div>
                  {complaint.incident_date && (
                    <div>
                      <strong>Incident Date:</strong> {complaint.incident_date}
                    </div>
                  )}
                  {complaint.incident_time && (
                    <div>
                      <strong>Incident Time:</strong> {complaint.incident_time}
                    </div>
                  )}
                </div>

                {complaint.location && (
                  <div style={{ marginBottom: '15px' }}>
                    <strong>Location:</strong> {complaint.location}
                  </div>
                )}

                {complaint.admin_notes && (
                  <div style={{ marginBottom: '15px', padding: '10px', backgroundColor: '#f3f4f6', borderRadius: '5px' }}>
                    <strong>Admin Notes:</strong> {complaint.admin_notes}
                  </div>
                )}

                <div style={{ marginTop: '15px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                  {complaint.status !== 'under_review' && (
                    <button
                      onClick={() => updateComplaintStatus(complaint.id, 'under_review')}
                      style={{
                        padding: '8px 16px',
                        backgroundColor: '#3b82f6',
                        color: 'white',
                        border: 'none',
                        borderRadius: '5px',
                        cursor: 'pointer'
                      }}
                    >
                      Mark Under Review
                    </button>
                  )}
                  {complaint.status !== 'resolved' && (
                    <button
                      onClick={() => updateComplaintStatus(complaint.id, 'resolved')}
                      style={{
                        padding: '8px 16px',
                        backgroundColor: '#10b981',
                        color: 'white',
                        border: 'none',
                        borderRadius: '5px',
                        cursor: 'pointer'
                      }}
                    >
                      Mark Resolved
                    </button>
                  )}
                  {complaint.status !== 'rejected' && (
                    <button
                      onClick={() => {
                        const notes = prompt('Enter rejection reason:');
                        if (notes) updateComplaintStatus(complaint.id, 'rejected', notes);
                      }}
                      style={{
                        padding: '8px 16px',
                        backgroundColor: '#ef4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: '5px',
                        cursor: 'pointer'
                      }}
                    >
                      Reject
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'sos' && (
        <div>
          <h2>SOS Emergency Alerts</h2>
          <div style={{ display: 'grid', gap: '20px' }}>
            {sosAlerts.map((alert) => (
              <div key={alert.id} style={{
                border: '2px solid #dc2626',
                borderRadius: '10px',
                padding: '20px',
                backgroundColor: alert.status === 'active' ? '#fef2f2' : '#f9fafb',
                boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
                  <div>
                    <h3 style={{ margin: '0 0 5px 0', color: '#dc2626', fontSize: '24px' }}>🚨 EMERGENCY ALERT</h3>
                    <p style={{ margin: '0', fontSize: '16px', fontWeight: 'bold' }}>{alert.user_name}</p>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <span style={{
                      padding: '5px 12px',
                      borderRadius: '20px',
                      fontSize: '12px',
                      fontWeight: 'bold',
                      backgroundColor: alert.status === 'active' ? '#dc2626' : alert.status === 'resolved' ? '#10b981' : '#6b7280',
                      color: 'white'
                    }}>
                      {alert.status.toUpperCase()}
                    </span>
                    <p style={{ margin: '5px 0 0 0', fontSize: '12px', color: '#6b7280' }}>
                      {formatDate(alert.alert_timestamp)}
                    </p>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginBottom: '15px' }}>
                  <div>
                    <strong>Phone:</strong> {alert.user_id}
                  </div>
                  <div>
                    <strong>Police Station:</strong> {alert.police_station || 'Not specified'}
                  </div>
                  <div>
                    <strong>Coordinates:</strong> {alert.latitude.toFixed(6)}, {alert.longitude.toFixed(6)}
                  </div>
                  <div>
                    <strong>Status:</strong> {alert.status.toUpperCase()}
                  </div>
                </div>

                {alert.location_address && (
                  <div style={{ marginBottom: '15px' }}>
                    <strong>Location:</strong> {alert.location_address}
                  </div>
                )}

                <div style={{ marginBottom: '15px' }}>
                  <strong>Emergency Contacts:</strong>
                  <div style={{ marginTop: '5px' }}>
                    {alert.emergency_contacts && alert.emergency_contacts.length > 0 ? (
                      alert.emergency_contacts.map((contact, index) => (
                        <span key={index} style={{
                          display: 'inline-block',
                          backgroundColor: '#e5e7eb',
                          padding: '2px 8px',
                          borderRadius: '12px',
                          margin: '2px 4px 2px 0',
                          fontSize: '12px'
                        }}>
                          {contact}
                        </span>
                      ))
                    ) : (
                      <span style={{ color: '#6b7280' }}>No emergency contacts listed</span>
                    )}
                  </div>
                </div>

                {/* Google Maps Link */}
                <div style={{ marginBottom: '15px' }}>
                  <a
                    href={`https://www.google.com/maps?q=${alert.latitude},${alert.longitude}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      padding: '8px 16px',
                      backgroundColor: '#4285f4',
                      color: 'white',
                      textDecoration: 'none',
                      borderRadius: '5px',
                      fontSize: '14px'
                    }}
                  >
                    🗺️ View on Google Maps
                  </a>
                </div>

                {alert.notes && (
                  <div style={{ marginBottom: '15px', padding: '10px', backgroundColor: '#f3f4f6', borderRadius: '5px' }}>
                    <strong>Admin Notes:</strong> {alert.notes}
                  </div>
                )}

                {alert.resolved_by && (
                  <div style={{ marginBottom: '15px', fontSize: '12px', color: '#6b7280' }}>
                    <strong>Resolved by:</strong> {alert.resolved_by} on {alert.resolved_at ? formatDate(alert.resolved_at) : 'Unknown'}
                  </div>
                )}

                <div style={{ marginTop: '15px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                  {alert.status === 'active' && (
                    <>
                      <button
                        onClick={() => {
                          const resolvedBy = prompt('Enter your name:');
                          if (resolvedBy) updateSOSAlertStatus(alert.id, 'resolved', resolvedBy, 'Emergency handled successfully');
                        }}
                        style={{
                          padding: '10px 20px',
                          backgroundColor: '#10b981',
                          color: 'white',
                          border: 'none',
                          borderRadius: '5px',
                          cursor: 'pointer',
                          fontWeight: 'bold'
                        }}
                      >
                        ✅ Mark as Resolved
                      </button>
                      <button
                        onClick={() => {
                          const resolvedBy = prompt('Enter your name:');
                          const notes = prompt('Enter reason for false alarm:');
                          if (resolvedBy && notes) updateSOSAlertStatus(alert.id, 'false_alarm', resolvedBy, notes);
                        }}
                        style={{
                          padding: '10px 20px',
                          backgroundColor: '#f59e0b',
                          color: 'white',
                          border: 'none',
                          borderRadius: '5px',
                          cursor: 'pointer',
                          fontWeight: 'bold'
                        }}
                      >
                        ⚠️ False Alarm
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}
            {sosAlerts.length === 0 && (
              <div style={{
                textAlign: 'center',
                padding: '40px',
                backgroundColor: '#f9fafb',
                borderRadius: '10px',
                border: '2px dashed #e5e7eb'
              }}>
                <h3 style={{ color: '#6b7280', margin: '0 0 10px 0' }}>No SOS Alerts</h3>
                <p style={{ color: '#9ca3af', margin: '0' }}>Emergency alerts will appear here when users trigger SOS.</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default AdminPanel;