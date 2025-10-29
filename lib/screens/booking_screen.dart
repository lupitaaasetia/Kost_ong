// screens/booking_screen.dart - Updated with dual action buttons
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kost.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final BaseKost kost;

  const BookingScreen({super.key, required this.kost});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();

  late BookingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BookingViewModel(bookingService: _bookingService);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      if (!_viewModel.validateBooking()) {
        _showValidationError();
        return;
      }

      final booking = _viewModel.createBooking(
        kost: widget.kost,
        userEmail: 'user@email.com',
        notes: _viewModel.notes,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(booking: booking),
        ),
      );
    }
  }

  void _showValidationError() {
    String message = '';
    if (_viewModel.selectedRoom == null) {
      message = 'Silakan pilih kamar terlebih dahulu';
    } else if (_viewModel.checkInDate == null ||
        _viewModel.checkOutDate == null) {
      message = 'Silakan pilih tanggal check-in dan check-out';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.checkInDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.kost.getPrimaryColor(),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _viewModel.setCheckInDate(picked);
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _viewModel.checkOutDate ??
          _viewModel.checkInDate?.add(const Duration(days: 30)) ??
          DateTime.now(),
      firstDate: _viewModel.checkInDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.kost.getPrimaryColor(),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _viewModel.setCheckOutDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Kost'),
        backgroundColor: widget.kost.getPrimaryColor(),
        foregroundColor: Colors.white,
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
            _buildPriceSummaryCard(),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildKostInfoCard() {
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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.kost.getPrimaryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.kost.getKostIcon(),
                    color: widget.kost.getPrimaryColor(),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kost.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.kost.address,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                  widget.kost.getFormattedPrice(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.kost.getPrimaryColor(),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.meeting_room, color: widget.kost.getPrimaryColor()),
                const SizedBox(width: 8),
                const Text(
                  'Pilih Kamar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _viewModel.availableRooms.length,
              itemBuilder: (context, index) {
                final room = _viewModel.availableRooms[index];
                final isSelected = _viewModel.selectedRoom == room;
                return GestureDetector(
                  onTap: () => setState(() => _viewModel.selectRoom(room)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? widget.kost.getPrimaryColor().withOpacity(0.1)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? widget.kost.getPrimaryColor()
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: widget.kost.getPrimaryColor(),
                        child: Text(
                          room.roomNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'Kamar ${room.roomNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${room.floor} • ${room.size}m² • ${room.bedType}',
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                room.hasWindow
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 14,
                                color: room.hasWindow
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                room.hasWindow
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
                          ? Icon(
                              Icons.check_circle,
                              color: widget.kost.getPrimaryColor(),
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
                  Icons.calendar_today,
                  color: widget.kost.getPrimaryColor(),
                ),
                const SizedBox(width: 8),
                const Text(
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
                    date: _viewModel.checkInDate,
                    onTap: _selectCheckInDate,
                    icon: Icons.login,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'Check-out',
                    date: _viewModel.checkOutDate,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: widget.kost.getPrimaryColor()),
                const SizedBox(width: 8),
                const Text(
                  'Durasi Sewa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.kost.getPrimaryColor().withOpacity(0.1),
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
                        '${_viewModel.duration} bulan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.kost.getPrimaryColor(),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _viewModel.duration > 1
                            ? () => setState(_viewModel.decreaseDuration)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: widget.kost.getPrimaryColor(),
                      ),
                      IconButton(
                        onPressed: () => setState(_viewModel.increaseDuration),
                        icon: const Icon(Icons.add_circle_outline),
                        color: widget.kost.getPrimaryColor(),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: widget.kost.getPrimaryColor()),
                const SizedBox(width: 8),
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => _viewModel.setNotes(value),
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

  Widget _buildPriceSummaryCard() {
    final monthlyPrice = widget.kost.pricePerMonth;
    final totalRent = _viewModel.calculateTotalPrice(monthlyPrice);
    final deposit = _viewModel.calculateDepositAmount(monthlyPrice);
    final grandTotal = totalRent + deposit;

    return Card(
      elevation: 4,
      color: widget.kost.getPrimaryColor().withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: widget.kost.getPrimaryColor()),
                const SizedBox(width: 8),
                const Text(
                  'Ringkasan Biaya',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPriceRow(
              'Sewa (${_viewModel.duration} bulan)',
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(totalRent),
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Deposit (1 bulan)',
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(deposit),
            ),
            const Divider(height: 24),
            _buildPriceRow(
              'Total Pembayaran',
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(grandTotal),
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
            color: isTotal ? widget.kost.getPrimaryColor() : Colors.black87,
          ),
        ),
      ],
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
                onPressed: _proceedToPayment,
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Bayar Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.kost.getPrimaryColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// View Model untuk Booking Screen menggunakan OOP principles
class BookingViewModel {
  final BookingService _bookingService;

  RoomDetail? _selectedRoom;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _duration = 1;
  String _notes = '';
  List<RoomDetail> _availableRooms = [];
  late TextEditingController _notesController;

  RoomDetail? get selectedRoom => _selectedRoom;
  DateTime? get checkInDate => _checkInDate;
  DateTime? get checkOutDate => _checkOutDate;
  int get duration => _duration;
  String get notes => _notes;
  List<RoomDetail> get availableRooms => _availableRooms;

  BookingViewModel({required BookingService bookingService})
    : _bookingService = bookingService;

  void initialize() {
    _notesController = TextEditingController();
    _availableRooms = _bookingService.getAvailableRooms();
    _checkInDate = DateTime.now().add(const Duration(days: 7));
    _checkOutDate = _checkInDate!.add(Duration(days: 30 * _duration));
  }

  void dispose() {
    _notesController.dispose();
  }

  void selectRoom(RoomDetail room) {
    _selectedRoom = room;
  }

  void setCheckInDate(DateTime date) {
    _checkInDate = date;
    if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
      _checkOutDate = _checkInDate!.add(Duration(days: 30 * _duration));
    }
    _calculateDuration();
  }

  void setCheckOutDate(DateTime date) {
    _checkOutDate = date;
    _calculateDuration();
  }

  void setNotes(String value) {
    _notes = value;
  }

  void increaseDuration() {
    _duration++;
    if (_checkInDate != null) {
      _checkOutDate = _checkInDate!.add(Duration(days: 30 * _duration));
    }
  }

  void decreaseDuration() {
    if (_duration > 1) {
      _duration--;
      if (_checkInDate != null) {
        _checkOutDate = _checkInDate!.add(Duration(days: 30 * _duration));
      }
    }
  }

  void _calculateDuration() {
    if (_checkInDate != null && _checkOutDate != null) {
      final difference = _checkOutDate!.difference(_checkInDate!).inDays;
      _duration = (difference / 30).ceil();
      if (_duration < 1) _duration = 1;
    }
  }

  int calculateTotalPrice(int pricePerMonth) {
    return pricePerMonth * _duration;
  }

  double calculateDepositAmount(int pricePerMonth) {
    return pricePerMonth * 1.0;
  }

  bool validateBooking() {
    return _selectedRoom != null &&
        _checkInDate != null &&
        _checkOutDate != null;
  }

  Booking createBooking({
    required BaseKost kost,
    required String userEmail,
    String? notes,
  }) {
    return _bookingService.createBooking(
      kost: kost,
      userEmail: userEmail,
      roomDetail: _selectedRoom!,
      checkInDate: _checkInDate!,
      checkOutDate: _checkOutDate!,
      duration: _duration,
      notes: notes,
    );
  }
}
