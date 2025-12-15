const mongoose = require('mongoose');
const BookingSchema = new mongoose.Schema({
  // Kembalikan ke ObjectId agar sesuai dengan validasi MongoDB
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  kost_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kost' },
  start_date: Date,
  end_date: Date,
  status: { type: String, default: 'pending' },
  total: Number,
  createdAt: { type: Date, default: Date.now },
  
  // Field tambahan tetap ada
  nama_kost: String,
  nomor_kamar: String,
  metode_pembayaran: String,
  catatan: String,

}, { collection: 'booking' });
module.exports = mongoose.model('Booking', BookingSchema);
