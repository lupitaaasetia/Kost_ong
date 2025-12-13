import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final filters = ['Semua', 'Pending', 'Dikonfirmasi', 'Ditolak'];
      setState(() {
        _selectedFilter = filters[_tabController.index];
        _filterBookings();
      });
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);

    final result = await ApiService.fetchBooking(widget.token);

    if (result['success'] == true) {
      setState(() {
        _allBookings = result['data'] ?? [];
        _filterBookings();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _showSnackBar(result['message'] ?? 'Gagal memuat booking', isError: true);
    }
  }

  void _filterBookings() {
    if (_selectedFilter == 'Semua') {
      _filteredBookings = _allBookings;
    } else {
      _filteredBookings = _allBookings
          .where(
            (b) =>
                b['status']?.toString().toLowerCase() ==
                _selectedFilter.toLowerCase(),
          )
          .toList();
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    final result = await ApiService.updateBookingStatus(
      widget.token,
      bookingId,
      status,
    );

    if (result['success'] == true) {
      _showSnackBar('Status booking berhasil diperbarui');
      _loadBookings();
    } else {
      _showSnackBar(
        result['message'] ?? 'Gagal memperbarui status',
        isError: true,
      );
    }
  }

  void _showBookingDetail(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailSheet(
        booking: booking,
        onStatusUpdate: (status) {
          Navigator.pop(context);
          _updateBookingStatus(booking['id'].toString(), status);
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Kelola Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF667eea),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF667eea),
          tabs: [
            Tab(text: 'Semua'),
            Tab(text: 'Pending'),
            Tab(text: 'Dikonfirmasi'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: _filteredBookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = _filteredBookings[index];
                        return _buildBookingCard(booking);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Tidak ada booking',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Booking akan muncul di sini',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'dikonfirmasi':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'ditolak':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

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
                          booking['nama_pemesan']?.toString() ?? 'Pemesan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          booking['kost_name']?.toString() ?? 'Kost',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          booking['status']?.toString() ?? 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Tanggal: ${booking['tanggal_booking'] ?? '-'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (booking['nomor_kamar'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'Kamar: ${booking['nomor_kamar']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (status == 'pending') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateBookingStatus(
                          booking['id'].toString(),
                          'Ditolak',
                        ),
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateBookingStatus(
                          booking['id'].toString(),
                          'Dikonfirmasi',
                        ),
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Terima'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
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
  final Function(String) onStatusUpdate;

  const BookingDetailSheet({
    Key? key,
    required this.booking,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';

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
                Text(
                  'Detail Booking',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDetailRow(
              'Nama Pemesan',
              booking['nama_pemesan']?.toString() ?? '-',
              Icons.person,
            ),
            _buildDetailRow(
              'Nama Kost',
              booking['kost_name']?.toString() ?? '-',
              Icons.home_work,
            ),
            _buildDetailRow(
              'Nomor Kamar',
              booking['nomor_kamar']?.toString() ?? '-',
              Icons.meeting_room,
            ),
            _buildDetailRow(
              'Tanggal Booking',
              booking['tanggal_booking']?.toString() ?? '-',
              Icons.calendar_today,
            ),
            _buildDetailRow(
              'No. Telepon',
              booking['no_telepon']?.toString() ?? '-',
              Icons.phone,
            ),
            _buildDetailRow(
              'Email',
              booking['email']?.toString() ?? '-',
              Icons.email,
            ),
            if (booking['catatan'] != null) ...[
              SizedBox(height: 16),
              Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(booking['catatan'].toString()),
              ),
            ],
            if (status == 'pending') ...[
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatusUpdate('Ditolak'),
                      icon: Icon(Icons.close),
                      label: Text('Tolak Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onStatusUpdate('Dikonfirmasi'),
                      icon: Icon(Icons.check),
                      label: Text('Terima Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
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
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
