const express = require('express');
const router = express.Router();
const Message = require('../models/Message');
const verifyToken = require('../middleware/authMiddleware');
const mongoose = require('mongoose');
const User = require('../models/User'); // Pastikan model User diimport
const Kost = require('../models/Kost'); // Pastikan model Kost diimport

// GET semua pesan untuk sebuah chat room (antara 2 user untuk 1 kost)
router.get('/:kost_id/:user1_id/:user2_id', verifyToken, async (req, res) => {
  try {
    const { kost_id, user1_id, user2_id } = req.params;
    const messages = await Message.find({
      kost_id: kost_id,
      $or: [
        { sender_id: user1_id, receiver_id: user2_id },
        { sender_id: user2_id, receiver_id: user1_id },
      ],
    }).sort({ created_at: 'asc' });
    res.json({ success: true, data: messages });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// POST kirim pesan baru
router.post('/', verifyToken, async (req, res) => {
  try {
    const { kost_id, receiver_id, message } = req.body;
    const sender_id = req.user.id;

    console.log(`Pesan baru dari ${sender_id} ke ${receiver_id} untuk kost ${kost_id}`);

    const newMessage = new Message({
      kost_id,
      sender_id,
      receiver_id,
      message,
    });

    const savedMessage = await newMessage.save();
    res.status(201).json({ success: true, data: savedMessage });
  } catch (err) {
    console.error("Error kirim pesan:", err);
    res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});

// ✅ PERBAIKAN: GET daftar chat room dengan LOGIKA JAVASCRIPT (Lebih Andal)
router.get('/rooms', verifyToken, async (req, res) => {
    try {
        const userIdStr = req.user.id.toString();
        console.log(`Mencari chat rooms untuk user: ${userIdStr}`);

        // 1. Cari semua pesan yang melibatkan user ini
        const messages = await Message.find({
            $or: [{ sender_id: req.user.id }, { receiver_id: req.user.id }]
        })
        .sort({ created_at: -1 }) // Urutkan dari yang terbaru
        .populate('sender_id', 'nama_lengkap')
        .populate('receiver_id', 'nama_lengkap')
        .populate('kost_id', 'nama_kost');

        console.log(`Ditemukan ${messages.length} pesan mentah.`);

        // 2. Kelompokkan pesan berdasarkan "Room" (Kost + Lawan Bicara)
        const roomsMap = new Map();

        for (const msg of messages) {
            if (!msg.kost_id || !msg.sender_id || !msg.receiver_id) continue; // Skip jika data tidak lengkap

            const senderId = msg.sender_id._id.toString();
            const receiverId = msg.receiver_id._id.toString();
            
            // Tentukan siapa lawan bicaranya
            const otherUserId = senderId === userIdStr ? receiverId : senderId;
            const otherUserName = senderId === userIdStr ? msg.receiver_id.nama_lengkap : msg.sender_id.nama_lengkap;
            
            const kostId = msg.kost_id._id.toString();
            const kostName = msg.kost_id.nama_kost;

            // Kunci unik untuk room: KostID + UserLawan
            const key = `${kostId}_${otherUserId}`;

            // Jika room ini belum ada di map, tambahkan (karena pesan sudah diurutkan terbaru, yang pertama ketemu adalah last message)
            if (!roomsMap.has(key)) {
                roomsMap.set(key, {
                    kost_id: kostId,
                    kost_name: kostName,
                    other_user_id: otherUserId,
                    other_user_name: otherUserName,
                    last_message: msg.message,
                    created_at: msg.created_at,
                    sender_id: senderId,
                    receiver_id: receiverId,
                    // Info tambahan untuk debugging
                    my_id: userIdStr
                });
            }
        }

        const rooms = Array.from(roomsMap.values());
        console.log(`Ditemukan ${rooms.length} chat rooms unik.`);

        res.json({ success: true, data: rooms });

    } catch (err) {
        console.error("Error get rooms:", err);
        res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
});

module.exports = router;
