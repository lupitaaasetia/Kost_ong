const express = require('express');
const router = express.Router();
const Pembayaran = require('../models/Pembayaran');
const multer = require('multer');

// Konfigurasi Multer untuk upload gambar
const upload = multer({ dest: 'uploads/' });

// ✅ GET semua pembayaran
router.get('/', async (req, res) => {
  try {
    const payments = await Pembayaran.find().populate('user_id booking_id');
    res.json(payments);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ POST membuat pembayaran baru (DENGAN UPLOAD BUKTI)
router.post('/', upload.single('bukti_bayar'), async (req, res) => {
  try {
    const { booking_id, metode_pembayaran, total_bayar } = req.body;
    const buktiBayarPath = req.file ? req.file.path : null;

    if (!booking_id || !metode_pembayaran || !total_bayar || !buktiBayarPath) {
      return res.status(400).json({
        success: false,
        message: 'Data tidak lengkap atau bukti bayar tidak diunggah.',
      });
    }

    const newPayment = new Pembayaran({
      booking_id,
      metode_pembayaran,
      total_bayar: Number(total_bayar),
      bukti_pembayaran: buktiBayarPath,
      status_pembayaran: 'pending', // Status awal
    });

    const savedPayment = await newPayment.save();
    res.status(201).json({ success: true, data: savedPayment });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

module.exports = router;