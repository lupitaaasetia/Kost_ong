const mongoose = require('mongoose');

// ✅ PERBAIKAN: Menyamakan nama field dengan frontend
const KostSchema = new mongoose.Schema({
  nama_kost: String,
  deskripsi: String,
  alamat: String,
  harga: Number,
  foto_kost: [String],
  fasilitas: [String],
  pemilik_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  jenis_kost: String,
  status: String,
  createdAt: { type: Date, default: Date.now }
}, { collection: 'kost' });

module.exports = mongoose.model('Kost', KostSchema);
