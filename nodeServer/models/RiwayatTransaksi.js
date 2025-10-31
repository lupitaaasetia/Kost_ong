const express = require('express');
const router = express.Router();
const Riwayat = require('../models/RiwayatTransaksi');

// ✅ Get semua riwayat
router.get('/', async (req, res) => {
  try {
    const data = await Riwayat.find().populate('user_id');
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ Get riwayat berdasarkan user
router.get('/user/:id', async (req, res) => {
  try {
    const data = await Riwayat.find({ user_id: req.params.id }).populate('user_id');
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
