const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const verifyToken = require('../middleware/authMiddleware');

// ✅ GET semua booking
router.get('/', async (req, res) => {
  try {
    // Menggunakan id_user & id_kost sesuai model Flutter
    const bookings = await Booking.find()
      .populate('id_user')
      .populate('id_kost'); 
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ GET booking per user (Endpoint yang akan dipakai di History Screen)
router.get('/user/:id_user', verifyToken, async (req, res) => {
  try {
    const { id_user } = req.params;
    // Cari berdasarkan id_user, dan populate data id_kost agar nama kost muncul
    const bookings = await Booking.find({ id_user: id_user })
      .populate('id_kost') 
      .sort({ created_at: -1 }); // Urutkan dari yang terbaru

    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ POST buat booking baru
router.post('/', verifyToken, async (req, res) => {
  try {
    const payload = req.body;
    // Pastikan menyimpan dengan field id_user
    payload.id_user = req.user.id; 
    const booking = await Booking.create(payload);
    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;