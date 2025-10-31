const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const verifyToken = require('../middleware/authMiddleware');

// ✅ GET semua booking
router.get('/', async (req, res) => {
  try {
    const bookings = await Booking.find().populate('user_id kost_id');
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ GET booking per user
router.get('/user/:user_id', verifyToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    const bookings = await Booking.find({ user_id }).populate('kost_id');
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ POST buat booking baru
router.post('/', verifyToken, async (req, res) => {
  try {
    const payload = req.body;
    payload.user_id = req.user.id;
    const booking = await Booking.create(payload);
    res.json(booking);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
