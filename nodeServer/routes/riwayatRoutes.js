const express = require('express');
const router = express.Router();
const Riwayat = require('../models/RiwayatTransaksi');

// ✅ GET semua riwayat
router.get('/', async (req, res) => {
  try {
    const riwayat = await Riwayat.find().populate('user_id kost_id');
    res.json(riwayat);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
