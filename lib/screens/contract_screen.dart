// screens/contract_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class ContractScreen extends StatefulWidget {
  final Booking booking;

  const ContractScreen({super.key, required this.booking});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  final BookingService _bookingService = BookingService();
  Contract? _contract;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  void _loadContract() {
    setState(() {
      _contract = _bookingService.getContractByBookingId(widget.booking.id);
    });
  }

  // PDF helper removed

  @override
  Widget build(BuildContext context) {
    if (_contract == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kontrak Sewa'),
          backgroundColor: widget.booking.kost.getPrimaryColor(),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrak Sewa'),
        backgroundColor: widget.booking.kost.getPrimaryColor(),
        foregroundColor: Colors.white,
        actions: [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSuccessCard(),
          const SizedBox(height: 16),
          _buildContractInfoCard(),
          const SizedBox(height: 16),
          _buildPartiesCard(),
          const SizedBox(height: 16),
          _buildRentalDetailsCard(),
          const SizedBox(height: 16),
          _buildTermsCard(),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      elevation: 4,
      color: Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kontrak sewa Anda telah dibuat',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: widget.booking.kost.getPrimaryColor(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Informasi Kontrak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow2('Nomor Kontrak', _contract!.contractNumber),
            _buildInfoRow2(
              'Tanggal',
              DateFormat('dd MMMM yyyy').format(_contract!.signedDate),
            ),
            _buildInfoRow2('Status', 'Aktif', valueColor: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildPartiesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: widget.booking.kost.getPrimaryColor(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pihak yang Terlibat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'PIHAK PERTAMA (Pemilik)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow2('Nama', _contract!.landlordName),
            _buildInfoRow2('Telepon', widget.booking.kost.phoneNumber),
            const SizedBox(height: 16),
            const Text(
              'PIHAK KEDUA (Penyewa)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow2('Nama', widget.booking.userEmail),
            _buildInfoRow2('Email', widget.booking.userEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: widget.booking.kost.getPrimaryColor()),
                const SizedBox(width: 8),
                const Text(
                  'Detail Sewa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow2('Kost', widget.booking.kost.name),
            _buildInfoRow2('Kamar', widget.booking.roomDetail.roomNumber),
            _buildInfoRow2('Ukuran', '${widget.booking.roomDetail.size}m²'),
            _buildInfoRow2('Lantai', widget.booking.roomDetail.floor),
            _buildInfoRow2(
              'Periode',
              '${DateFormat('dd MMM yyyy').format(_contract!.startDate)} - ${DateFormat('dd MMM yyyy').format(_contract!.endDate)}',
            ),
            _buildInfoRow2('Durasi', '${widget.booking.duration} bulan'),
            const Divider(height: 24),
            _buildInfoRow2(
              'Biaya Sewa',
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(widget.booking.totalPrice),
              valueColor: widget.booking.kost.getPrimaryColor(),
            ),
            _buildInfoRow2(
              'Deposit',
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(widget.booking.depositAmount),
              valueColor: widget.booking.kost.getPrimaryColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: widget.booking.kost.getPrimaryColor()),
                const SizedBox(width: 8),
                const Text(
                  'Syarat dan Ketentuan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _contract!.terms,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow2(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text(
                  'Kembali ke Home',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.booking.kost.getPrimaryColor(),
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
}
