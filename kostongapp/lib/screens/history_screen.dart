import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/profile_view_model.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

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

  Future<List<BookingModel>> _loadBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final String? userString = prefs.getString('user');
      
      if (token == null || userString == null) {
        return [];
      }

      final user = jsonDecode(userString);
      final String userId = user['_id'] ?? user['id'] ?? '';

      if (userId.isEmpty) return [];

      // Menggunakan endpoint yang sudah kita perbaiki di backend
      return ApiService.fetchUserBookings(token, userId);
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Transaksi'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } 
            
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
                return _buildTransactionCard(trx);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BookingModel trx) {
    // Normalisasi status
    String status = trx.statusBooking.toLowerCase();
    String displayStatus = 'Pending';
    Color statusColor = Colors.orange;

    if (status == 'active' || status == 'confirmed' || status == 'dikonfirmasi') {
      displayStatus = 'Berhasil';
      statusColor = Colors.green;
    } else if (status == 'cancelled' || status == 'rejected' || status == 'ditolak') {
      displayStatus = 'Dibatalkan';
      statusColor = Colors.red;
    }

    // Format tanggal
    String dateStr = trx.tanggalMasuk;
    try {
      final date = DateTime.parse(trx.tanggalMasuk);
      dateStr = DateFormat('dd MMM yyyy').format(date);
    } catch (_) {}

    // Format harga
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String priceStr = currencyFormatter.format(trx.totalHarga);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trx.namaKost ?? 'Kost',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Check-in: $dateStr', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Durasi: ${trx.durasiSewa} Bulan', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembayaran', style: TextStyle(fontSize: 14)),
                Text(
                  priceStr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
