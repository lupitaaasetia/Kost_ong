const express = require('express');
const router = express.Router();
const Notifikasi = require('../models/Notifikasi');

// ✅ GET semua notifikasi
router.get('/', async (req, res) => {
  try {
    const notif = await Notifikasi.find();
    res.json(notif);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
