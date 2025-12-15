const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  sender_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  receiver_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  kost_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kost', required: true },
  message: { type: String, required: true },
  is_read: { type: Boolean, default: false },
  created_at: { type: Date, default: Date.now }
}, { collection: 'messages' });

module.exports = mongoose.model('Message', MessageSchema);
