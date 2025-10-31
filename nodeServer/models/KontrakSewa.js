const mongoose = require('mongoose');

const KontrakSchema = new mongoose.Schema({
  booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  pemilik_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  kost_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kost' },
  kamar_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kamar' },
  nomor_kontrak: String,
  tanggal_mulai: Date,
  tanggal_selesai: Date,
  durasi: Number,
  tipe_durasi: String,
  harga_sewa: Number,
  total_dibayar: Number,
  status_kontrak: String,
  ketentuan: [String],
  file_kontrak: String,
  ttd_penyewa: Boolean,
  ttd_pemilik: Boolean,
  tanggal_ttd: Date,
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now },
}, { collection: 'kontrak_sewa' });

module.exports = mongoose.model('kontrak_sewa', KontrakSchema);
