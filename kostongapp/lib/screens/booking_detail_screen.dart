import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookingDetailScreen extends StatefulWidget {
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  String? token;
  dynamic booking;
  bool loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      token = args['token'];
      booking = args['booking'];
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => loading = true);

    try {
      final response = await ApiService.updateBookingStatus(
        token,
        booking['id'],
        status,
      );

      if (response['success'] == true) {
        _showSnackBar('Status booking berhasil diupdate');
        await Future.delayed(Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar(
          response['message'] ?? 'Gagal update status',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan', isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showConfirmDialog(String status, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(status);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF667eea)),
            child: Text('Ya'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'dikonfirmasi':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'ditolak':
        return Colors.red;
      case 'completed':
      case 'selesai':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Detail Booking')),
        body: Center(child: Text('Data tidak ditemukan')),
      );
    }

    final status = booking['status']?.toString() ?? 'Pending';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Detail Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Status Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 60,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ID Booking: #${booking['id']?.toString() ?? '-'}',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi Pemesan
                        _buildSection(
                          title: 'Informasi Pemesan',
                          icon: Icons.person,
                          children: [
                            _buildInfoRow(
                              'Nama',
                              booking['nama_pemesan']?.toString() ?? '-',
                              Icons.person_outline,
                            ),
                            _buildInfoRow(
                              'Email',
                              booking['email']?.toString() ?? '-',
                              Icons.email_outlined,
                            ),
                            _buildInfoRow(
                              'No. Telepon',
                              booking['no_telepon']?.toString() ?? '-',
                              Icons.phone_outlined,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Informasi Kost
                        _buildSection(
                          title: 'Informasi Kost',
                          icon: Icons.home_work,
                          children: [
                            _buildInfoRow(
                              'Nama Kost',
                              booking['nama_kost']?.toString() ?? '-',
                              Icons.home_outlined,
                            ),
                            _buildInfoRow(
                              'Nomor Kamar',
                              booking['nomor_kamar']?.toString() ?? '-',
                              Icons.meeting_room_outlined,
                            ),
                            _buildInfoRow(
                              'Harga',
                              'Rp ${booking['harga']?.toString() ?? '0'}',
                              Icons.payments_outlined,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Informasi Booking
                        _buildSection(
                          title: 'Detail Booking',
                          icon: Icons.event_note,
                          children: [
                            _buildInfoRow(
                              'Tanggal Booking',
                              booking['tanggal_booking']?.toString() ?? '-',
                              Icons.calendar_today_outlined,
                            ),
                            _buildInfoRow(
                              'Check In',
                              booking['check_in']?.toString() ?? '-',
                              Icons.login_outlined,
                            ),
                            _buildInfoRow(
                              'Durasi',
                              '${booking['durasi']?.toString() ?? '0'} Bulan',
                              Icons.timelapse_outlined,
                            ),
                          ],
                        ),

                        if (booking['catatan'] != null &&
                            booking['catatan'].toString().isNotEmpty) ...[
                          SizedBox(height: 16),
                          _buildSection(
                            title: 'Catatan',
                            icon: Icons.note,
                            children: [
                              Text(
                                booking['catatan'].toString(),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Action Buttons
                        if (status.toLowerCase() == 'pending') ...[
                          SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showConfirmDialog(
                                    'rejected',
                                    'Tolak booking ini?',
                                  ),
                                  icon: Icon(Icons.close),
                                  label: Text('Tolak'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showConfirmDialog(
                                    'confirmed',
                                    'Konfirmasi booking ini?',
                                  ),
                                  icon: Icon(Icons.check),
                                  label: Text('Konfirmasi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'dikonfirmasi':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
      case 'ditolak':
        return Icons.cancel;
      case 'completed':
      case 'selesai':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF667eea), size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[700]),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
