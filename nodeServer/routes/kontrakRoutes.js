const express = require('express');
const router = express.Router();
const Kontrak = require('../models/KontrakSewa');

// ✅ Get semua kontrak
router.get('/', async (req, res) => {
  try {
    const data = await Kontrak.find()
      .populate('user_id')
      .populate('pemilik_id')
      .populate('kost_id')
      .populate('kamar_id');
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ Get kontrak berdasarkan user
router.get('/user/:id', async (req, res) => {
  try {
    const data = await Kontrak.find({ user_id: req.params.id })
      .populate('kost_id')
      .populate('pemilik_id');
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
