const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  nama_lengkap: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  no_telepon: { type: String, required: true },
  role: { 
    type: String, 
    enum: ['pencari', 'pemilik'], 
    default: 'pencari',
    required: true 
  },
  // Field Wajib Database (Kita beri default agar tidak error saat register)
  jenis_kelamin: { type: String, default: 'Lainnya' }, 
  tanggal_lahir: { type: Date, default: Date.now }, 
  
  // Nested Object Alamat yang Wajib
  alamat: {
    jalan: { type: String, default: '-' },
    kecamatan: { type: String, default: '-' },
    kelurahan: { type: String, default: '-' },
    kode_pos: { type: String, default: '-' },
    kota: { type: String, default: '-' },
    provinsi: { type: String, default: '-' }
  },

  verified: { type: Boolean, default: false },
  
  // Field Optional (Tidak required di validator database)
  ktp: { type: String },
  npwp: { type: String },
  rekening: {
    nama_bank: String,
    nama_pemilik: String,
    nomor_rekening: String
  }
}, { 
  collection: 'user',
  // PENTING: Mapping timestamp mongoose ke format database (snake_case)
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } 
});

module.exports = mongoose.model('User', UserSchema);