const express = require('express');
const router = express.Router();
const Review = require('../models/Review');
const verifyToken = require('../middleware/authMiddleware');

// GET semua review untuk sebuah kost
router.get('/kost/:kost_id', async (req, res) => {
  try {
    const reviews = await Review.find({ kost_id: req.params.kost_id })
      .populate('user_id', 'nama_lengkap') // Ambil nama user
      .sort({ created_at: -1 });
    res.json({ success: true, data: reviews });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// POST buat review baru
router.post('/', verifyToken, async (req, res) => {
  try {
    const { kost_id, rating, content } = req.body;
    const user_id = req.user.id;

    const newReview = new Review({
      kost_id,
      user_id,
      rating,
      content,
    });

    const savedReview = await newReview.save();
    res.status(201).json({ success: true, data: savedReview });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

module.exports = router;
