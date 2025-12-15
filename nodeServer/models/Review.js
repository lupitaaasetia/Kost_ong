const mongoose = require('mongoose');

const ReviewSchema = new mongoose.Schema({
  kost_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kost', required: true },
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  rating: { type: Number, required: true },
  content: { type: String, required: true },
  created_at: { type: Date, default: Date.now }
}, { collection: 'reviews' });

module.exports = mongoose.model('Review', ReviewSchema);
