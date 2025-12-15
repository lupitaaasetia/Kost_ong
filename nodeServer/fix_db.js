require('dotenv').config();
const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI;

const fixDatabase = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;

    // Hapus validasi schema dari koleksi 'booking'
    try {
      await db.command({
        collMod: 'booking',
        validator: {},
        validationLevel: 'off'
      });
      console.log('✅ Validasi koleksi "booking" berhasil dihapus!');
    } catch (e) {
      console.warn('⚠️ Gagal menghapus validasi "booking" (mungkin tidak ada). Melanjutkan...');
    }

    // Hapus validasi schema dari koleksi 'kost'
    try {
      await db.command({
        collMod: 'kost',
        validator: {},
        validationLevel: 'off'
      });
      console.log('✅ Validasi koleksi "kost" berhasil dihapus!');
    } catch (e) {
      console.warn('⚠️ Gagal menghapus validasi "kost" (mungkin tidak ada). Melanjutkan...');
    }

    console.log('Proses selesai.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Gagal terhubung atau menjalankan perintah:', err);
    process.exit(1);
  }
};

fixDatabase();
