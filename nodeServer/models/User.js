const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String },
  // Tambahkan Role
  role: { 
    type: String, 
    enum: ['pencari', 'pemilik'], 
    default: 'pencari',
    required: true 
  },
  avatar: { type: String },
  createdAt: { type: Date, default: Date.now }
}, { collection: 'user' });

module.exports = mongoose.model('User', UserSchema);