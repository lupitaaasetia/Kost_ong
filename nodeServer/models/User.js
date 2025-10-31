const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String },
  avatar: { type: String },
  createdAt: { type: Date, default: Date.now }
}, { collection: 'user' });

module.exports = mongoose.model('User', UserSchema);
