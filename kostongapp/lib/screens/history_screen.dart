import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/profile_view_model.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final ProfileTabViewModel viewModel;

  const HistoryScreen({Key? key, required this.viewModel}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<BookingModel>> _bookingFuture;

  @override
  void initState() {
    super.initState();
    _bookingFuture = _loadBookings();
  }

  // Fungsi untuk memuat data booking user yang sedang login
  Future<List<BookingModel>> _loadBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final String? userString = prefs.getString('user');
      
      if (token == null || userString == null) {
        // Jika tidak ada sesi login, kembalikan list kosong
        return [];
      }

      final user = jsonDecode(userString);
      // Ambil ID user, menyesuaikan field _id atau id
      final String userId = user['_id'] ?? user['id'] ?? '';

      if (userId.isEmpty) return [];

      return ApiService.fetchUserBookings(token, userId);
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      return []; // Return empty list on error to avoid breaking UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _bookingFuture = _loadBookings();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          // 1. Status Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          // 2. Status Error
          else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('Terjadi kesalahan: ${snapshot.error}', textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => setState(() => _bookingFuture = _loadBookings()),
                    child: const Text('Coba Lagi'),
                  )
                ],
              ),
            );
          } 
          
          // 3. Status Kosong atau Sukses
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Belum ada transaksi', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final trx = transactions[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(Icons.home_work, color: Colors.blueAccent),
                  ),
                  title: Text(
                    trx.namaKost ?? 'Kost', // Menampilkan nama kost dari database
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Tgl Masuk: ${trx.tanggalMasuk}'),
                      Text('Durasi: ${trx.durasiSewa} Bulan'),
                      const SizedBox(height: 4),
                      Text(
                        'Total: Rp ${trx.totalHarga}',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                  trailing: _buildStatusBadge(trx.statusBooking),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ID Booking: ${trx.id}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
      case 'success':
      case 'berhasil':
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
      case 'menunggu':
        color = Colors.orange;
        break;
      case 'cancelled':
      case 'gagal':
      case 'ditolak':
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}