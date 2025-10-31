const express = require('express');
const router = express.Router();
const Pembayaran = require('../models/Pembayaran');

// ✅ GET semua pembayaran
router.get('/', async (req, res) => {
  try {
    const payments = await Pembayaran.find().populate('user_id booking_id');
    res.json(payments);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
