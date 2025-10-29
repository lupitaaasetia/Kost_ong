// screens/owner_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kostqu/models/booking.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';

class OwnerApprovalScreen extends StatefulWidget {
  final Booking booking;
  final String ownerEmail;

  const OwnerApprovalScreen({
    super.key,
    required this.booking,
    required this.ownerEmail,
  });

  @override
  State<OwnerApprovalScreen> createState() => _OwnerApprovalScreenState();
}

class _OwnerApprovalScreenState extends State<OwnerApprovalScreen> {
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Permintaan Booking'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(),

            // Kost Information
            _buildKostInfoCard(),

            // Booking Details
            _buildBookingDetailsCard(),

            // Customer Information
            _buildCustomerInfoCard(),

            // Payment Information
            _buildPaymentInfoCard(),

            // Owner Notes (if any)
            if (widget.booking.status != BookingStatus.pending)
              _buildNotesCard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: widget.booking.status == BookingStatus.pending
          ? _buildActionButtons()
          : null,
    );
  }

  Widget _buildStatusBanner() {
    Color bgColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (widget.booking.status) {
      case BookingStatus.confirmed:
        bgColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        statusText = 'Booking Disetujui';
        break;
      case BookingStatus.rejected:
        bgColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.cancel;
        statusText = 'Booking Ditolak';
        break;
      case BookingStatus.cancelled:
        bgColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.block;
        statusText = 'Booking Dibatalkan';
        break;
      default:
        bgColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.pending;
        statusText = 'Menunggu Persetujuan';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKostInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kost Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              // Use kost primary image if available, otherwise fallback asset
              widget.booking.kost.imageUrls.isNotEmpty
                  ? widget.booking.kost.imageUrls.first
                  : 'assets/images/logo.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.kost.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.booking.kost.address,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B46C1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bed, color: Color(0xFF6B46C1), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tipe: ${widget.booking.roomDetail.bedType}',
                        style: const TextStyle(
                          color: Color(0xFF6B46C1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return _buildSectionCard(
      title: 'Detail Booking',
      icon: Icons.calendar_today,
      children: [
        _buildDetailRow('ID Booking', widget.booking.id, Icons.tag),
        const Divider(height: 24),
        _buildDetailRow(
          'Tanggal Check-in',
          _formatDate(widget.booking.checkInDate),
          Icons.login,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Tanggal Check-out',
          _formatDate(widget.booking.checkOutDate),
          Icons.logout,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Durasi',
          '${_calculateDuration()} hari',
          Icons.timelapse,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          'Tanggal Booking',
          _formatDate(widget.booking.bookingDate),
          Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    return _buildSectionCard(
      title: 'Informasi Penyewa',
      icon: Icons.person,
      children: [
        _buildDetailRow(
          'Nama',
          widget.booking.userEmail.split('@')[0],
          Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Email',
          widget.booking.userEmail,
          Icons.email_outlined,
        ),
        const SizedBox(height: 12),
        _buildDetailRow('No. Telepon', '-', Icons.phone_outlined),
      ],
    );
  }

  Widget _buildPaymentInfoCard() {
    return _buildSectionCard(
      title: 'Informasi Pembayaran',
      icon: Icons.payments,
      children: [
        _buildDetailRow(
          'Harga per Bulan',
          widget.booking.kost.pricePerMonth.toString(),
          Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Total Pembayaran',
          widget.booking.totalPrice.toString(),
          Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Status Pembayaran',
          widget.booking.getPaymentStatusText(),
          Icons.receipt_long,
          valueColor: widget.booking.paymentStatus == PaymentStatus.paid
              ? Colors.green
              : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    String noteTitle = widget.booking.status == BookingStatus.confirmed
        ? 'Catatan Persetujuan'
        : 'Alasan Penolakan';

    return _buildSectionCard(
      title: noteTitle,
      icon: Icons.note,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.booking.notes ?? 'Tidak ada catatan',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF6B46C1), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _showRejectDialog(),
                icon: const Icon(Icons.cancel),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _showApproveDialog(),
                icon: const Icon(Icons.check_circle),
                label: const Text('Setujui'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Setujui Booking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin menyetujui permintaan booking ini?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Tambahkan catatan untuk penyewa...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Tolak Booking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin menolak permintaan booking ini?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan *',
                hintText: 'Berikan alasan penolakan...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap berikan alasan penolakan'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _rejectBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _approveBooking() async {
    setState(() => _isProcessing = true);

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    _bookingService.approveBooking(
      widget.booking.id,
      _notesController.text.trim(),
    );

    // Send a system notification to the user
    _notificationService.createSystemNotification(
      widget.booking.userEmail,
      'Booking Disetujui! 🎉',
      'Booking Anda untuk ${widget.booking.kost.name} telah disetujui.',
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil disetujui!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    }
  }

  void _rejectBooking() async {
    setState(() => _isProcessing = true);

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    _bookingService.rejectBooking(
      widget.booking.id,
      _notesController.text.trim(),
    );

    _notificationService.createSystemNotification(
      widget.booking.userEmail,
      'Booking Ditolak',
      'Mohon maaf, booking Anda untuk ${widget.booking.kost.name} ditolak.',
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil ditolak'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    }
  }

  int _calculateDuration() {
    try {
      // Simple duration calculation (assumes format like "1 Jan 2024")
      // In real app, use proper date parsing
      return 30; // Default 30 days
    } catch (e) {
      return 0;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return dt.toIso8601String();
    }
  }
}
