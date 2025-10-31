const mongoose = require('mongoose');
const BookingSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  kost_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kost' },
  start_date: Date,
  end_date: Date,
  status: { type: String, default: 'pending' },
  total: Number,
  createdAt: { type: Date, default: Date.now }
}, { collection: 'booking' });
module.exports = mongoose.model('Booking', BookingSchema);
