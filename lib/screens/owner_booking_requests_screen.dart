import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import 'owner_approval_screen.dart';

class OwnerBookingRequestsScreen extends StatefulWidget {
  final String ownerEmail;

  const OwnerBookingRequestsScreen({super.key, required this.ownerEmail});

  @override
  State<OwnerBookingRequestsScreen> createState() =>
      _OwnerBookingRequestsScreenState();
}

class _OwnerBookingRequestsScreenState
    extends State<OwnerBookingRequestsScreen> {
  final BookingService _bookingService = BookingService();

  List<Booking> _ownerBookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    final all = _bookingService.getAllBookings();
    _ownerBookings = all
        .where((b) => b.kost.ownerEmail == widget.ownerEmail)
        .toList();
    // show pending first
    _ownerBookings.sort((a, b) => a.status.index.compareTo(b.status.index));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Booking'),
        backgroundColor: const Color(0xFF6B46C1),
      ),
      body: _ownerBookings.isEmpty
          ? Center(child: Text('Tidak ada permintaan booking'))
          : ListView.builder(
              itemCount: _ownerBookings.length,
              itemBuilder: (context, index) {
                final b = _ownerBookings[index];
                return ListTile(
                  leading: b.kost.imageUrls.isNotEmpty
                      ? Image.network(
                          b.kost.imageUrls.first,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                        ),
                  title: Text(b.kost.name),
                  subtitle: Text(
                    'Penyewa: ${b.userEmail.split('@')[0]} — ${b.getStatusText()}',
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OwnerApprovalScreen(
                          booking: b,
                          ownerEmail: widget.ownerEmail,
                        ),
                      ),
                    );

                    if (result == true) {
                      // Refresh list
                      _loadBookings();
                    }
                  },
                );
              },
            ),
    );
  }
}
