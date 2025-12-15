const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const verifyToken = require('../middleware/authMiddleware');

// Register
router.post('/register', async (req, res) => {
  try {
    const { nama_lengkap, email, password, no_telepon, role } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({
      nama_lengkap,
      email,
      password: hashedPassword,
      no_telepon,
      role,
    });
    res.status(201).json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Registrasi gagal', error: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }

    // ✅ PERBAIKAN: Cek password plain text DULU (untuk akun lama)
    let isMatch = false;
    if (user.password === password) {
        isMatch = true;
        // Opsional: Update password ke hash agar lebih aman ke depannya
        // const hashedPassword = await bcrypt.hash(password, 10);
        // await User.findByIdAndUpdate(user._id, { password: hashedPassword });
    } else {
        // Jika tidak cocok plain text, coba cek hash (untuk akun baru)
        isMatch = await bcrypt.compare(password, user.password);
    }

    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Password salah' });
    }

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1d' });
    res.json({ success: true, token, role: user.role, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Login gagal', error: err.message });
  }
});

// Get User Profile
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Gagal mengambil profil', error: err.message });
  }
});

// Update User Profile
router.put('/profile', verifyToken, async (req, res) => {
  try {
    const { nama_lengkap, no_telepon, jenis_kelamin, tanggal_lahir, alamat } = req.body;
    const updatedUser = await User.findByIdAndUpdate(
      req.user.id,
      { nama_lengkap, no_telepon, jenis_kelamin, tanggal_lahir, alamat },
      { new: true }
    ).select('-password');
    res.json({ success: true, message: 'Profil berhasil diperbarui', data: updatedUser });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Gagal memperbarui profil', error: err.message });
  }
});

module.exports = router;
