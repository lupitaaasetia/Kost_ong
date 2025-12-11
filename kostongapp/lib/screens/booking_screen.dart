import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pembayaran_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> kostData;

  const BookingScreen({Key? key, required this.kostData}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _duration = 1;
  String? _selectedRoom;
  final TextEditingController _notesController = TextEditingController();

  // Sample rooms data
  final List<Map<String, dynamic>> _availableRooms = [
    {
      'number': 'A1',
      'floor': 'Lantai 1',
      'size': 12,
      'bedType': 'Single Bed',
      'hasWindow': true,
      'available': true,
    },
    {
      'number': 'A2',
      'floor': 'Lantai 1',
      'size': 15,
      'bedType': 'Queen Bed',
      'hasWindow': true,
      'available': true,
    },
    {
      'number': 'B1',
      'floor': 'Lantai 2',
      'size': 10,
      'bedType': 'Single Bed',
      'hasWindow': false,
      'available': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now().add(const Duration(days: 7));
    _checkOutDate = _checkInDate!.add(Duration(days: 30 * _duration));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // FIXED: Handle berbagai tipe data untuk harga
  int _getHargaAsInt() {
    try {
      final harga = widget.kostData['harga'];
      if (harga == null) return 0;

      if (harga is int) return harga;
      if (harga is double) return harga.toInt();
      if (harga is String) {
        // Remove non-numeric characters
        final cleanedHarga = harga.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(cleanedHarga) ?? 0;
      }

      return 0;
    } catch (e) {
      print('Error parsing harga: $e');
      return 0;
    }
  }

  int _calculateTotalPrice() {
    return _getHargaAsInt() * _duration;
  }

  int _calculateDeposit() {
    return _getHargaAsInt(); // Deposit 1 bulan
  }

  // FIXED: Format harga dengan benar
  String _formatHarga(int harga) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(harga);
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoom == null) {
        _showSnackBar('Silakan pilih kamar terlebih dahulu', isError: true);
        return;
      }

      if (_checkInDate == null || _checkOutDate == null) {
        _showSnackBar(
          'Silakan pilih tanggal check-in dan check-out',
          isError: true,
        );
        return;
      }

      // FIXED: Pastikan semua data dalam format yang benar
      final bookingData = {
        'kost_id':
            widget.kostData['_id']?.toString() ??
            widget.kostData['id']?.toString() ??
            '',
        'nama_kost': widget.kostData['nama_kost']?.toString() ?? 'Nama Kost',
        'alamat': widget.kostData['alamat']?.toString() ?? 'Alamat',
        'tipe_kamar': widget.kostData['tipe_kamar']?.toString() ?? 'Standard',
        'harga': _getHargaAsInt(),
        'room_number': _selectedRoom!,
        'check_in_date': DateFormat('yyyy-MM-dd').format(_checkInDate!),
        'check_out_date': DateFormat('yyyy-MM-dd').format(_checkOutDate!),
        'duration': _duration,
        'notes': _notesController.text,
        'total_price': _calculateTotalPrice(),
        'deposit': _calculateDeposit(),
        'pemilik_nama':
            widget.kostData['pemilik_nama']?.toString() ?? 'Pemilik Kost',
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(bookingData: bookingData),
        ),
      ).then((result) {
        if (result == 'payment_success') {
          Navigator.pop(context, 'booking_success');
        }
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4facfe)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
          _checkOutDate = _checkInDate!.add(Duration(days: 30 * _duration));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _checkOutDate ??
          _checkInDate?.add(const Duration(days: 30)) ??
          DateTime.now(),
      firstDate: _checkInDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4facfe)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _checkOutDate = picked;
        _calculateDuration();
      });
    }
  }

  void _calculateDuration() {
    if (_checkInDate != null && _checkOutDate != null) {
      final difference = _checkOutDate!.difference(_checkInDate!).inDays;
      setState(() {
        _duration = (difference / 30).ceil();
        if (_duration < 1) _duration = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRent = _calculateTotalPrice();
    final deposit = _calculateDeposit();
    final grandTotal = totalRent + deposit;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Booking Kost'),
        backgroundColor: const Color(0xFF4facfe),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildKostInfoCard(),
            const SizedBox(height: 16),
            _buildRoomSelectionCard(),
            const SizedBox(height: 16),
            _buildDateSelectionCard(),
            const SizedBox(height: 16),
            _buildDurationCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
            const SizedBox(height: 16),
            _buildPriceSummaryCard(totalRent, deposit, grandTotal),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(grandTotal),
    );
  }

  Widget _buildKostInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_work,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kostData['nama_kost']?.toString() ?? 'Nama Kost',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.kostData['alamat']?.toString() ?? 'Alamat',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Harga per bulan:', style: TextStyle(fontSize: 14)),
                Text(
                  '${_formatHarga(_getHargaAsInt())}/bulan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4facfe),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.meeting_room, color: Color(0xFF4facfe)),
                SizedBox(width: 8),
                Text(
                  'Pilih Kamar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableRooms.length,
              itemBuilder: (context, index) {
                final room = _availableRooms[index];
                final isSelected = _selectedRoom == room['number'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedRoom = room['number']),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? const Color(0xFF4facfe).withOpacity(0.1)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF4facfe)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF4facfe),
                        child: Text(
                          room['number'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'Kamar ${room['number']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${room['floor']} â€¢ ${room['size']}mÂ² â€¢ ${room['bedType']}',
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                room['hasWindow']
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 14,
                                color: room['hasWindow']
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                room['hasWindow']
                                    ? 'Ada jendela'
                                    : 'Tanpa jendela',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4facfe),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFF4facfe)),
                SizedBox(width: 8),
                Text(
                  'Tanggal Sewa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Check-in',
                    date: _checkInDate,
                    onTap: _selectCheckInDate,
                    icon: Icons.login,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'Check-out',
                    date: _checkOutDate,
                    onTap: _selectCheckOutDate,
                    icon: Icons.logout,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? DateFormat('dd MMM yyyy').format(date)
                  : 'Pilih tanggal',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Color(0xFF4facfe)),
                SizedBox(width: 8),
                Text(
                  'Durasi Sewa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4facfe).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Durasi',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_duration bulan',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4facfe),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _duration > 1
                            ? () {
                                setState(() {
                                  _duration--;
                                  if (_checkInDate != null) {
                                    _checkOutDate = _checkInDate!.add(
                                      Duration(days: 30 * _duration),
                                    );
                                  }
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF4facfe),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _duration++;
                            if (_checkInDate != null) {
                              _checkOutDate = _checkInDate!.add(
                                Duration(days: 30 * _duration),
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF4facfe),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: Color(0xFF4facfe)),
                SizedBox(width: 8),
                Text(
                  'Catatan (Opsional)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan atau permintaan khusus...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard(int totalRent, int deposit, int grandTotal) {
    return Card(
      elevation: 2,
      color: const Color(0xFF4facfe).withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt, color: Color(0xFF4facfe)),
                SizedBox(width: 8),
                Text(
                  'Ringkasan Biaya',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPriceRow('Sewa ($_duration bulan)', _formatHarga(totalRent)),
            const SizedBox(height: 8),
            _buildPriceRow('Deposit (1 bulan)', _formatHarga(deposit)),
            const Divider(height: 24),
            _buildPriceRow(
              'Total Pembayaran',
              _formatHarga(grandTotal),
              isTotal: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deposit akan dikembalikan setelah masa sewa berakhir',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF4facfe) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(int grandTotal) {
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
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _formatHarga(grandTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4facfe),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _proceedToPayment,
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Lanjut Bayar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4facfe),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
