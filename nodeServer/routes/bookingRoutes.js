const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const verifyToken = require('../middleware/authMiddleware');
const mongoose = require('mongoose');

// GET semua booking
router.get('/', async (req, res) => {
  try {
    const bookings = await Booking.find()
      .populate('user_id')
      .populate('kost_id'); 
    res.json({ success: true, data: bookings });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// GET booking per user
router.get('/user/:user_id', verifyToken, async (req, res) => {
  try {
    const { user_id } = req.params;
    const bookings = await Booking.find({ user_id: user_id })
      .populate('kost_id') 
      .sort({ created_at: -1 });

    res.json({ success: true, data: bookings });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// POST buat booking baru
router.post('/', verifyToken, async (req, res) => {
  try {
    const payload = req.body;
    const now = new Date();
    const expiredAt = new Date(now);
    expiredAt.setHours(now.getHours() + 24);

    const nomorBooking = 'BOOK-' + Date.now() + Math.floor(Math.random() * 1000);

    const bookingData = {
        user_id: new mongoose.Types.ObjectId(req.user.id),
        kost_id: new mongoose.Types.ObjectId(payload.kost_id),
        kamar_id: new mongoose.Types.ObjectId(payload.kost_id),
        nomor_booking: nomorBooking,
        tanggal_mulai: new Date(payload.start_date),
        tanggal_selesai: new Date(payload.end_date),
        durasi: parseInt(payload.durasi_sewa || 1),
        tipe_durasi: 'bulan',
        harga_total: payload.total,
        biaya_admin: 0,
        total_bayar: payload.total,
        metode_pembayaran: payload.metode_pembayaran,
        status_booking: 'pending',
        catatan: payload.catatan || '-',
        created_at: now,
        updated_at: now,
        expired_at: expiredAt
    };

    const booking = await mongoose.connection.collection('booking').insertOne(bookingData);
    
    res.status(201).json({ success: true, data: booking });
  } catch (err) {
    if (err.code === 121) {
        console.error("❌ VALIDASI GAGAL (POST)! Detail:", JSON.stringify(err.errInfo.details, null, 2));
    } else {
        console.error("Error lain (POST):", err);
    }
    res.status(500).json({ success: false, message: 'Server error: ' + err.message, error: err.message });
  }
});

// PUT update status booking
router.put('/:id/status', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        console.log(`Mencoba update ID: ${id} dengan status: ${status}`);

        // Gunakan updateOne langsung ke MongoDB driver untuk melihat error validasi asli
        const result = await mongoose.connection.collection('booking').updateOne(
            { _id: new mongoose.Types.ObjectId(id) },
            { 
                $set: { 
                    status_booking: status, 
                    updated_at: new Date() 
                } 
            }
        );

        if (result.matchedCount === 0) {
            return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
        }

        // Ambil data terbaru setelah update
        const updatedBooking = await Booking.findById(id)
            .populate('user_id', 'nama_lengkap')
            .populate('kost_id', 'nama_kost');

        console.log("✅ Hasil Update:", updatedBooking);
        res.json({ success: true, message: 'Status booking diperbarui', data: updatedBooking });

    } catch (err) {
        // Tangkap error validasi MongoDB
        if (err.code === 121) {
            console.error("❌ VALIDASI GAGAL (PUT)! Detail:", JSON.stringify(err.errInfo.details, null, 2));
        } else {
            console.error("Error saat update status:", err);
        }
        res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
});

module.exports = router;