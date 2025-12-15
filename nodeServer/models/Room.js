const mongoose = require('mongoose');

const RoomSchema = new mongoose.Schema({
  kost_id: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Kost',
    required: true 
  },
  nomor_kamar: { 
    type: String,
    required: true 
  },
  harga: { 
    type: Number,
    required: true 
  },
  deskripsi: String,
  status: { 
    type: String, 
    default: 'Tersedia' // Tersedia, Terisi, Maintenance
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
}, { collection: 'rooms' });

module.exports = mongoose.model('Room', RoomSchema);
