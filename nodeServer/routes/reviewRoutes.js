const express = require('express');
const router = express.Router();
const Review = require('../models/Review');

// ✅ GET semua review
router.get('/', async (req, res) => {
  try {
    const reviews = await Review.find().populate('user_id kost_id');
    res.json(reviews);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
