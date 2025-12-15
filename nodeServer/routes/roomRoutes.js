const express = require('express');
const router = express.Router();
const Room = require('../models/Room');
const verifyToken = require('../middleware/authMiddleware');

// GET semua kamar untuk sebuah kost
router.get('/kost/:kost_id', verifyToken, async (req, res) => {
  try {
    console.log(`Mencari kamar untuk kost_id: ${req.params.kost_id}`); // DEBUG LOG
    const rooms = await Room.find({ kost_id: req.params.kost_id });
    console.log(`Ditemukan ${rooms.length} kamar.`); // DEBUG LOG
    res.json({ success: true, data: rooms });
  } catch (err) {
    console.error("Error fetch kamar:", err);
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// POST buat kamar baru
router.post('/', verifyToken, async (req, res) => {
  try {
    const room = await Room.create(req.body);
    res.status(201).json({ success: true, data: room });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// PUT update kamar by ID
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const updatedRoom = await Room.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updatedRoom) {
      return res.status(404).json({ success: false, message: 'Kamar tidak ditemukan' });
    }
    res.json({ success: true, data: updatedRoom });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// DELETE kamar by ID
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const deletedRoom = await Room.findByIdAndDelete(req.params.id);
    if (!deletedRoom) {
      return res.status(404).json({ success: false, message: 'Kamar tidak ditemukan' });
    }
    res.json({ success: true, message: 'Kamar berhasil dihapus' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

module.exports = router;
