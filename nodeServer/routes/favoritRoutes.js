const express = require('express');
const router = express.Router();
const Favorit = require('../models/Favorit');

// ✅ GET semua favorit
router.get('/', async (req, res) => {
  try {
    const favorit = await Favorit.find().populate('user_id kost_id');
    res.json(favorit);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
