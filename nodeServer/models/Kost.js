const mongoose = require('mongoose');
const KostSchema = new mongoose.Schema({
  title: String,
  description: String,
  address: String,
  price: Number,
  photos: [String],
  facilities: [String],
  owner: String,
  createdAt: { type: Date, default: Date.now }
}, { collection: 'kost' });
module.exports = mongoose.model('Kost', KostSchema);
