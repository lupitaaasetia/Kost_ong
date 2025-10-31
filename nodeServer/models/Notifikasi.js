const mongoose = require('mongoose');
const NotifikasiSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  title: String,
  body: String,
  createdAt: { type: Date, default: Date.now },
  read: { type: Boolean, default: false }
}, { collection: 'notifikasi' });
module.exports = mongoose.model('Notifikasi', NotifikasiSchema);
