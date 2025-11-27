const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// ... (kode GET user tetap sama)

// ✅ REGISTER (Update untuk menerima Role)
router.post('/register', async (req, res) => {
  try {
    // Terima role dari body request
    const { name, email, password, phone, role } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: 'Email sudah digunakan' });

    // Validasi role agar hanya 'pencari' atau 'pemilik'
    const userRole = (role === 'pemilik') ? 'pemilik' : 'pencari';

    const user = await User.create({ 
      name, 
      email, 
      password, 
      phone, 
      role: userRole // Simpan role
    });

    res.status(201).json({ success: true, message: "Registrasi berhasil", data: user });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ✅ LOGIN (Tidak berubah banyak, data user sudah mengandung role)
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    if (user.password !== password) return res.status(401).json({ message: 'Password salah' });

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
    
    // Kirim data user termasuk role
    res.json({ success: true, message: 'Login berhasil', token, data: user });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
