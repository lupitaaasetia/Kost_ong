const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// ✅ REGISTER
router.post('/register', async (req, res) => {
  try {
    // 1. Terima data sesuai nama field baru (bahasa Indonesia)
    const { nama_lengkap, email, password, no_telepon, role } = req.body;

    // 2. Validasi input (Pastikan field ini tidak kosong/undefined)
    if (!nama_lengkap || !email || !password || !no_telepon) {
        return res.status(400).json({ 
            success: false,
            message: 'Mohon lengkapi semua data (nama, email, password, no hp)' 
        });
    }

    // 3. Cek duplikasi email
    const existingUser = await User.findOne({ email });
    if (existingUser) {
        return res.status(400).json({ 
            success: false,
            message: 'Email sudah digunakan' 
        });
    }

    // 4. Set Role
    const userRole = (role === 'pemilik') ? 'pemilik' : 'pencari';

    // 5. Simpan ke Database
    const user = await User.create({ 
      nama_lengkap,  
      email, 
      password, 
      no_telepon,    
      role: userRole,
      verified: false,
    });

    res.status(201).json({ success: true, message: "Registrasi berhasil", data: user });

  } catch (err) {
    console.error("Register Error:", err); // Print error di terminal Node.js untuk debugging
    res.status(500).json({ 
        success: false,
        message: 'Server error saat registrasi', 
        error: err.message 
    });
  }
});

// ✅ LOGIN (Update sedikit untuk konsistensi respons)
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    // Note: Di produksi sebaiknya gunakan bcrypt untuk compare password
    if (user.password !== password) return res.status(401).json({ message: 'Password salah' });

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    
    res.json({ success: true, message: 'Login berhasil', token, data: user });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;