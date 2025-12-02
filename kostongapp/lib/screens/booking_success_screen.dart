import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pencari_home_screen.dart'; // Pastikan import ini sesuai nama file home screen Anda

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> kostData;
  final DateTime startDate;
  final int duration;
  final int totalPrice;
  final String paymentMethod;

  const BookingSuccessScreen({
    Key? key,
    required this.kostData,
    required this.startDate,
    required this.duration,
    required this.totalPrice,
    required this.paymentMethod,
  }) : super(key: key);

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Sukses
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Terima kasih telah melakukan pembayaran.\nPesanan Anda akan segera diproses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Kartu Ringkasan
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Nama Kost',
                        kostData['nama_kost'] ?? '-',
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Kamar', kostData['room_number'] ?? '-'),
                      const Divider(height: 24),
                      _buildDetailRow('Check-in', _formatDate(startDate)),
                      const Divider(height: 24),
                      _buildDetailRow('Durasi', '$duration Bulan'),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Total Bayar',
                        _formatCurrency(totalPrice),
                        isBold: true,
                        valueColor: const Color(0xFF4facfe),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Tombol Kembali ke Beranda
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigasi Hapus semua route dan kembali ke Home
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeekerHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4facfe),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
