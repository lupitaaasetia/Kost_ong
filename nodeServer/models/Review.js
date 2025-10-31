const mongoose = require('mongoose');
const ReviewSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  kost_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kost' },
  rating: Number,
  comment: String,
  createdAt: { type: Date, default: Date.now }
}, { collection: 'review' });
module.exports = mongoose.model('Review', ReviewSchema);
