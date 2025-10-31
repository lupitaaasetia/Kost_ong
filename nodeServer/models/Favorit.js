const mongoose = require('mongoose');
const FavoritSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  kost_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Kost' },
  createdAt: { type: Date, default: Date.now }
}, { collection: 'favorit' });
module.exports = mongoose.model('Favorit', FavoritSchema);
