import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Tambahkan import dart:async

class ManageBookingsScreen extends StatefulWidget {
  final String token;

  const ManageBookingsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<dynamic> _allBookings = [];
  List<dynamic> _filteredBookings = [];
  late TabController _tabController;
  Timer? _autoRefreshTimer; // Timer untuk auto-refresh
  
  final List<String> _filters = ['Semua', 'Pending', 'Dikonfirmasi', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBookings();

    // ✅ FITUR BARU: Auto-refresh setiap 30 detik
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        // Panggil loadBookings tanpa loading indicator agar tidak mengganggu UI
        _loadBookings(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // Hentikan timer saat widget dibuang
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging && mounted) {
      _filterBookings();
    }
  }

  // Tambahkan parameter showLoading
  Future<void> _loadBookings({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);

    final result = await ApiService.fetchBooking(widget.token);

    if (mounted) {
      if (result['success'] == true) {
        final data = result['data'] ?? [];
        
        // DEBUG: Print data booking (opsional, bisa dihapus nanti)
        // print("--- LOAD BOOKINGS (Auto: ${!showLoading}) ---");

        setState(() {
          _allBookings = data;
          _filterBookings();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        // Jangan tampilkan snackbar error saat auto-refresh agar tidak spamming
        if (showLoading) {
          _showSnackBar(result['message'] ?? 'Gagal memuat booking', isError: true);
        }
      }
    }
  }

  void _filterBookings() {
    final selectedFilter = _filters[_tabController.index];
    setState(() {
      if (selectedFilter == 'Semua') {
        _filteredBookings = _allBookings;
      } else {
        _filteredBookings = _allBookings.where((b) {
          final status = _getNormalizedStatus(b);
          
          if (selectedFilter == 'Pending') return status == 'pending';
          if (selectedFilter == 'Dikonfirmasi') return status == 'active';
          if (selectedFilter == 'Ditolak') return status == 'cancelled';
          
          return false;
        }).toList();
      }
    });
  }

  String _getNormalizedStatus(Map<String, dynamic> booking) {
    String raw = (booking['status_booking'] ?? booking['status'])?.toString().toLowerCase().trim() ?? 'pending';
    
    if (raw == 'active' || raw == 'confirmed' || raw == 'dikonfirmasi' || raw == 'berhasil') {
      return 'active';
    }
    if (raw == 'cancelled' || raw == 'rejected' || raw == 'ditolak' || raw == 'gagal') {
      return 'cancelled';
    }
    return 'pending';
  }

  Future<void> _updateBookingStatus(String? bookingId, String action) async {
    if (bookingId == null) {
      _showSnackBar('ID Booking tidak valid', isError: true);
      return;
    }

    if (mounted) setState(() => _loading = true);

    String statusToSend = 'pending';
    if (action == 'Terima') statusToSend = 'active';
    if (action == 'Tolak') statusToSend = 'cancelled';
    
    final result = await ApiService.updateBookingStatus(widget.token, bookingId, statusToSend);

    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar('Status booking berhasil diperbarui');
        await _loadBookings(); 
      } else {
        setState(() => _loading = false);
        _showSnackBar(result['message'] ?? 'Gagal memperbarui status', isError: true);
      }
    }
  }

  void _showBookingDetail(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailSheet(
        booking: booking,
        status: _getNormalizedStatus(booking),
        onStatusUpdate: (action) {
          Navigator.pop(context);
          final bookingId = booking['_id']?.toString() ?? booking['id']?.toString();
          _updateBookingStatus(bookingId, action);
        },
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red[700] : Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Kelola Booking', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF667eea),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF667eea),
          isScrollable: true,
          tabs: _filters.map((filter) => Tab(text: filter.toUpperCase())).toList(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadBookings(showLoading: true),
              child: TabBarView(
                controller: _tabController,
                children: _filters.map((filter) {
                  return _filteredBookings.isEmpty
                      ? _buildEmptyState(filter)
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text('Tidak ada booking $filter', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final normalizedStatus = _getNormalizedStatus(booking);
    
    String displayStatus = 'Pending';
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending;

    if (normalizedStatus == 'active') {
      displayStatus = 'Dikonfirmasi';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (normalizedStatus == 'cancelled') {
      displayStatus = 'Ditolak';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }
    
    String formattedDate = booking['tanggal_mulai'] != null 
      ? DateFormat('dd MMM yyyy').format(DateTime.parse(booking['tanggal_mulai']))
      : '-';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetail(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF667eea).withOpacity(0.1),
                    child: Icon(Icons.person, color: Color(0xFF667eea)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['user_id']?['nama_lengkap']?.toString() ?? 'Pemesan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          booking['kost_id']?['nama_kost']?.toString() ?? 'Nama Kost',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Status dihapus dari sini sesuai permintaan sebelumnya
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Tanggal Mulai: $formattedDate', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
              if (booking['nomor_kamar'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text('Kamar: ${booking['nomor_kamar']}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BookingDetailSheet extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String status;
  final Function(String) onStatusUpdate;

  const BookingDetailSheet({
    Key? key, 
    required this.booking, 
    required this.status,
    required this.onStatusUpdate
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String displayStatus = 'Pending';
    Color statusColor = Colors.orange;

    if (status == 'active') {
      displayStatus = 'Dikonfirmasi';
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      displayStatus = 'Ditolak';
      statusColor = Colors.red;
    }

    bool isPending = status == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detail Booking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close)),
              ],
            ),
            SizedBox(height: 20),
            
            // Tampilkan Status di Detail
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  displayStatus.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            _buildDetailRow('Nama Pemesan', booking['user_id']?['nama_lengkap']?.toString() ?? '-', Icons.person),
            _buildDetailRow('Nama Kost', booking['kost_id']?['nama_kost']?.toString() ?? '-', Icons.home_work),
            _buildDetailRow('Nomor Kamar', booking['nomor_kamar']?.toString() ?? '-', Icons.meeting_room),
            _buildDetailRow('Tanggal Booking', booking['created_at'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(booking['created_at'])) : '-', Icons.calendar_today),
            _buildDetailRow('No. Telepon', booking['user_id']?['no_telepon']?.toString() ?? '-', Icons.phone),
            _buildDetailRow('Email', booking['user_id']?['email']?.toString() ?? '-', Icons.email),
            if (booking['catatan'] != null) ...[
              SizedBox(height: 16),
              Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Text(booking['catatan'].toString()),
              ),
            ],
            
            // Tombol Aksi hanya muncul jika status Pending
            if (isPending) ...[
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatusUpdate('Tolak'),
                      icon: Icon(Icons.close),
                      label: Text('Tolak Booking'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red), padding: EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onStatusUpdate('Terima'),
                      icon: Icon(Icons.check),
                      label: Text('Terima Booking'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Color(0xFF667eea)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
