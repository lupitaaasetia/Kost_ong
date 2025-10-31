const mongoose = require('mongoose');
const PembayaranSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
  amount: Number,
  method: String,
  status: String,
  createdAt: { type: Date, default: Date.now }
}, { collection: 'pembayaran' });
module.exports = mongoose.model('Pembayaran', PembayaranSchema);
