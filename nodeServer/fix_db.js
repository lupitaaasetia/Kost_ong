require('dotenv').config();
const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI;

const fixDatabase = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;

    // Hapus validasi schema dari koleksi 'booking'
    await db.command({
      collMod: 'booking',
      validator: {},
      validationLevel: 'off'
    });

    console.log('✅ Validasi koleksi booking berhasil dihapus!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Gagal:', err);
    process.exit(1);
  }
};

fixDatabase();
