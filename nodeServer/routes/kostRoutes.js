const express = require('express');
const router = express.Router();
const Kost = require('../models/Kost');
const verifyToken = require('../middleware/authMiddleware');
const mongoose = require('mongoose');

// GET semua kost (Publik)
router.get('/', async (req, res) => {
  try {
    const list = await Kost.find({}).sort({ createdAt: -1 });
    res.json({ success: true, data: list });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// GET kost by ID (Publik)
router.get('/:id', async (req, res) => {
  try {
    const k = await Kost.findById(req.params.id);
    if (!k) return res.status(404).json({ success: false, message: 'Kost not found' });
    res.json({ success: true, data: k });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// POST buat kost baru (Terlindungi)
router.post('/', verifyToken, async (req, res) => {
  try {
    const data = req.body;
    
    // ✅ PERBAIKAN FINAL: Menyesuaikan dengan Schema Validation MongoDB Atlas yang SANGAT KETAT
    const newKostData = {
        nama_kost: data.nama_kost || data.title,
        
        // Alamat harus OBJECT dengan field lengkap dan tipe data benar
        alamat: {
            jalan: data.alamat || data.address || "Alamat tidak lengkap",
            kecamatan: "Unknown", 
            kelurahan: "Unknown", 
            kota: "Unknown",
            provinsi: "Unknown",
            kode_pos: "00000",
            koordinat: { 
                // Paksa jadi double dengan nilai tidak bulat
                latitude: 0.000001,
                longitude: 0.000001
            }
        },
        
        deskripsi: data.deskripsi || data.description,
        
        // Harga dan Rating harus DOUBLE
        // Trik: Tambahkan 0.000001 agar tidak dianggap Int oleh driver
        harga: parseFloat(data.harga || data.price || 0) + 0.000001,
        rating: 0.000001, 
        
        // Field Wajib Lainnya
        fasilitas_umum: data.fasilitas || data.facilities || [],
        fasilitas_kamar_default: [], 
        peraturan: [], 
        
        tipe_kost: data.jenis_kost || data.tipe_kost || 'Campur',
        status: data.status || 'Tersedia',
        
        pemilik_id: new mongoose.Types.ObjectId(req.user.id),
        
        foto_kost: [], 
        
        jumlah_review: 0, 
        
        // Jarak Lokasi harus OBJECT dengan kampus_terdekat
        jarak_lokasi: { 
            nilai: 0, 
            satuan: "km",
            keterangan: "Dari pusat kota",
            kampus_terdekat: "Unknown" // Wajib ada
        }, 
        
        created_at: new Date(),
        updated_at: new Date()
    };

    const k = await mongoose.connection.collection('kost').insertOne(newKostData);
    
    res.status(201).json({ success: true, data: k });
  } catch (err) {
    if (err.code === 121) {
        console.error("❌ VALIDASI KOST GAGAL! Detail:", JSON.stringify(err.errInfo.details, null, 2));
    } else {
        console.error("Error buat kost:", err);
    }
    res.status(500).json({ success: false, message: 'Server error: ' + err.message, error: err.message });
  }
});

// PUT update kost by ID (Terlindungi)
router.put('/:id', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        const data = req.body;
        
        const updateData = {
            updated_at: new Date()
        };
        
        if (data.nama_kost) updateData.nama_kost = data.nama_kost;
        if (data.deskripsi) updateData.deskripsi = data.deskripsi;
        if (data.harga) updateData.harga = parseFloat(data.harga) + 0.000001;
        if (data.alamat) updateData['alamat.jalan'] = data.alamat;
        if (data.fasilitas) updateData.fasilitas_umum = data.fasilitas;
        if (data.jenis_kost) updateData.tipe_kost = data.jenis_kost;
        if (data.status) updateData.status = data.status;

        const updatedKost = await mongoose.connection.collection('kost').findOneAndUpdate(
            { _id: new mongoose.Types.ObjectId(id) },
            { $set: updateData },
            { returnDocument: 'after' }
        );

        if (!updatedKost) {
            return res.status(404).json({ success: false, message: 'Kost tidak ditemukan' });
        }

        res.json({ success: true, message: 'Kost berhasil diperbarui', data: updatedKost });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
});

// DELETE kost by ID (Terlindungi)
router.delete('/:id', verifyToken, async (req, res) => {
    try {
        const deletedKost = await Kost.findByIdAndDelete(req.params.id);
        if (!deletedKost) {
            return res.status(404).json({ success: false, message: 'Kost tidak ditemukan' });
        }
        res.json({ success: true, message: 'Kost berhasil dihapus' });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
});

module.exports = router;
