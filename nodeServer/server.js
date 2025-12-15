require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

const userRoutes = require('./routes/userRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const kostRoutes = require('./routes/kostRoutes');
const roomRoutes = require('./routes/roomRoutes');
const notifikasiRoutes = require('./routes/notifikasiRoutes');
const favoritRoutes = require('./routes/favoritRoutes');
const riwayatRoutes = require('./routes/riwayatRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const pembayaranRoutes = require('./routes/pembayaranRoutes');
const kontrakRoutes = require('./routes/kontrakRoutes');
const messageRoutes = require('./routes/messageRoutes'); // Import rute pesan

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;

connectDB(MONGO_URI);

app.use('/api/users', userRoutes);
app.use('/api/booking', bookingRoutes);
app.use('/api/kost', kostRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/notifikasi', notifikasiRoutes);
app.use('/api/favorit', favoritRoutes);
app.use('/api/riwayat', riwayatRoutes);
app.use('/api/review', reviewRoutes);
app.use('/api/pembayaran', pembayaranRoutes);
app.use('/api/kontrak', kontrakRoutes);
app.use('/api/messages', messageRoutes); // Daftarkan rute pesan

app.get('/', (req, res) => res.send('KostongApp API running'));

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
