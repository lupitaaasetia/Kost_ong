const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const verifyToken = require('../middleware/authMiddleware');

// ✅ REGISTER
router.post('/register', async (req, res) => {
  try {
    const { nama_lengkap, email, password, no_telepon, role, jenis_kelamin, tanggal_lahir, alamat } = req.body;

    if (!nama_lengkap || !email || !password || !no_telepon) {
        return res.status(400).json({ 
            success: false,
            message: 'Mohon lengkapi semua data (nama, email, password, no hp)' 
        });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
        return res.status(400).json({ 
            success: false,
            message: 'Email sudah digunakan' 
        });
    }

    const userRole = (role === 'pemilik') ? 'pemilik' : 'pencari';

    const user = await User.create({ 
      nama_lengkap,  
      email, 
      password, 
      no_telepon,    
      role: userRole,
      verified: false,
      jenis_kelamin,
      tanggal_lahir,
      alamat
    });

    res.status(201).json({ success: true, message: "Registrasi berhasil", data: user });

  } catch (err) {
    console.error("Register Error:", err);
    res.status(500).json({ 
        success: false,
        message: 'Server error saat registrasi', 
        error: err.message 
    });
  }
});

// ✅ LOGIN
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });

    if (user.password !== password) return res.status(401).json({ success: false, message: 'Password salah' });

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    
    res.json({ success: true, message: 'Login berhasil', token, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// ✅ GET USER PROFILE
router.get('/profile', verifyToken, async (req, res) => {
  try {
    // req.user.id didapat dari middleware verifyToken
    const user = await User.findById(req.user.id).select('-password'); // -password untuk tidak mengirim password
    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

module.exports = router;