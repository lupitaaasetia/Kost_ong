import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'add_edit_kost_screen.dart';
import 'manage_rooms_screen.dart';
import 'manage_reviews_screen.dart';
import 'manage_bookings_screen.dart';
import 'report_statitics_screen.dart';
import 'chat_detail_screen.dart';
import '../models/chat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OwnerHomeScreen extends StatefulWidget {
  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen>
    with TickerProviderStateMixin {
  bool loading = true;
  String? token;
  Map<String, dynamic> dataAll = {};

  String? userName;
  String? userId;
  String? userEmail;

  late AnimationController _animController;
  Timer? _autoRefreshTimer;
  Timer? _chatTimer;
  bool _isInit = true;
  int _selectedIndex = 0;

  int _unreadChatCount = 0;

  final Color _primaryColor = const Color(0xFF667eea);
  final Color _profileColor = const Color(0xFF6B46C1);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _autoRefreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (mounted) _loadAll(showLoading: false);
    });

    _chatTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) _updateUnreadChatCount();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _autoRefreshTimer?.cancel();
    _chatTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInit) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      token = args != null ? args['token'] as String? : null;

      if (args != null && args['data'] != null) {
        final userData = args['data'] as Map<String, dynamic>?;
        userName =
            userData?['nama_lengkap'] ??
            userData?['name'] ??
            userData?['email'];
        userId =
            userData?['_id']?.toString() ??
            userData?['id']?.toString() ??
            userData?['user_id']?.toString();
        userEmail = userData?['email']?.toString();
      }

      _loadAll();
      _isInit = false;
    }
  }

  void _updateUnreadChatCount() async {
    if (token == null) return;
    final result = await ApiService.fetchChatRooms(token!);
    if (result['success'] == true) {
      // Placeholder logic for unread count
    }
  }

  Future<void> _loadAll({bool showLoading = true}) async {
    if (showLoading) {
      if (mounted) setState(() => loading = true);
    }

    if (token == null) {
      if (mounted) {
        setState(() => loading = false);
        _showSnackBar(
          'Token tidak ditemukan, silakan login ulang.',
          isError: true,
        );
      }
      return;
    }

    _updateUnreadChatCount();

    final futures = await Future.wait([
      ApiService.fetchKost(token),
      ApiService.fetchBooking(token),
      ApiService.fetchPembayaran(token),
      ApiService.fetchReview(token!), 
      ApiService.fetchUserProfile(token!), 
    ]);

    final keys = ['kost', 'booking', 'pembayaran', 'review', 'user'];
    final tmp = <String, dynamic>{};

    for (int i = 0; i < keys.length; i++) {
      final r = futures[i] as Map<String, dynamic>;
      if (r['success'] == true) {
        tmp[keys[i]] = r['data'];
      } else {
        tmp[keys[i]] = {'error': r['message'] ?? 'gagal'};
      }
    }

    if (mounted) {
      setState(() {
        dataAll = tmp;
        loading = false;
        if (dataAll.containsKey('user') && dataAll['user'] is Map) {
          final userData = dataAll['user'] as Map<String, dynamic>;
          userName = userData['nama_lengkap'] ?? userName;
          userEmail = userData['email'] ?? userEmail;
          userId = userData['_id']?.toString() ?? userId;
        }
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logout() {
    setState(() {
      token = null;
    });
    Navigator.pushReplacementNamed(context, '/');
  }

  void _navigateToAddKost() async {
    if (token == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditKostScreen(token: token!)),
    );
    if (result == true) _loadAll(showLoading: false);
  }

  void _navigateToEditKost(Map<String, dynamic> kost) async {
    if (token == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditKostScreen(token: token!, kostData: kost),
      ),
    );
    if (result == true) _loadAll(showLoading: false);
  }

  void _navigateToManageRooms(Map<String, dynamic> kost) {
    if (token == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageRoomsScreen(
          kostId: kost['_id'].toString(),
          kostName: kost['nama_kost']?.toString() ?? 'Kost',
          token: token!,
        ),
      ),
    );
  }

  void _navigateToManageBookings() async {
    if (token == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageBookingsScreen(token: token!),
      ),
    );
    _loadAll(showLoading: false);
  }

  void _navigateToBookingRequests() async {
    if (token == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageBookingsScreen(token: token!),
      ),
    );
    _loadAll(showLoading: false);
  }

  void _navigateToReportsStatistics() {
    if (token == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsStatisticsScreen(token: token!),
      ),
    );
  }

  void _navigateToManageReviews() {
    if (token == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageReviewsScreen(token: token!),
      ),
    );
  }

  Future<void> _deleteKost(String? kostId) async {
    // Implementasi delete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Dashboard'
              : _selectedIndex == 1
              ? 'Kost Saya'
              : _selectedIndex == 2
              ? 'Booking'
              : _selectedIndex == 3
              ? 'Chat'
              : 'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: Icon(Icons.assessment),
              onPressed: _navigateToReportsStatistics,
            ),
            IconButton(
              icon: Icon(Icons.rate_review),
              onPressed: _navigateToManageReviews,
            ),
          ],
          if (_selectedIndex != 4)
            IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboardPage(),
                _buildKostPage(),
                _buildBookingPage(),
                _buildChatPage(),
                _buildProfilePage(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 3 || index == 4) {
            _loadAll(showLoading: false);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.home_work), label: 'Kost'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Book'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.chat_bubble_outline),
                if (_unreadChatCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text('$_unreadChatCount', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildKostPage() {
    final kostList = dataAll['kost'] is List ? dataAll['kost'] as List : [];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Properti Kost',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${kostList.length} properti terdaftar',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _navigateToAddKost,
                icon: Icon(Icons.add, size: 16),
                label: Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: kostList.isEmpty
              ? _buildEmptyKostState()
              : GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: kostList.length,
                  itemBuilder: (context, index) {
                    final kost = kostList[index];
                    return _buildKostGridCard(kost);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKostGridCard(dynamic kost) {
    String imageUrl = 'https://via.placeholder.com/300x200?text=No+Image';
    if (kost['foto_kost'] != null && (kost['foto_kost'] as List).isNotEmpty) {
      imageUrl = (kost['foto_kost'] as List)[0];
    }

    String lokasiDisplay = '-';
    final rawAlamat = kost['alamat'];

    if (rawAlamat is Map) {
      lokasiDisplay =
          rawAlamat['kota'] ?? rawAlamat['jalan'] ?? 'Lokasi tidak tersedia';
    } else if (rawAlamat is String) {
      lokasiDisplay = rawAlamat;
    } else {
      lokasiDisplay = rawAlamat?.toString() ?? '-';
    }

    double rating = double.tryParse(kost['rating']?.toString() ?? '0') ?? 0.0;
    int harga = int.tryParse(kost['harga']?.toString() ?? '0') ?? 0;
    String namaKost = kost['nama_kost'] ?? 'Tanpa Nama';
    String? kostId = kost['id']?.toString() ?? kost['_id']?.toString();

    return GestureDetector(
      onTap: () => _navigateToManageRooms(kost),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 18,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') _navigateToEditKost(kost);
                          if (value == 'delete') _deleteKost(kostId);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Hapus',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaKost,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 10,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                lokasiDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (rating > 0) ...[
                              Icon(Icons.star, size: 10, color: Colors.amber),
                              Text(
                                rating.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    Text(
                      'Rp ${_formatPrice(harga)}/bln',
                      style: TextStyle(
                        color: Color(0xFF4facfe),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyKostState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 100, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Belum ada kost',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mulai tambahkan properti kost Anda',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddKost,
            icon: Icon(Icons.add),
            label: Text('Tambah Kost Pertama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildDashboardPage() {
    final kostCount = dataAll['kost'] is List
        ? (dataAll['kost'] as List).length
        : 0;
    final bookingList = dataAll['booking'] is List
        ? (dataAll['booking'] as List)
        : [];
    final bookingCount = bookingList.length;
    final pendingBookings = bookingList
        .where((b) => b['status']?.toString().toLowerCase() == 'pending')
        .length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      userName ?? 'Pemilik Kost',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStatCard(
                  'Total Kost',
                  '$kostCount',
                  Icons.home_work,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDashboardStatCard(
                  'Booking',
                  '$bookingCount',
                  Icons.event_note,
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDashboardStatCard(
                  'Chat',
                  '$_unreadChatCount Baru',
                  Icons.chat,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDashboardStatCard(
                  'Pending',
                  '$pendingBookings',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStatCard(
    String title,
    String val,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey)),
          Text(
            val,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPage() {
    final bookingList = dataAll['booking'] is List
        ? (dataAll['booking'] as List)
        : [];
    if (bookingList.isEmpty) return Center(child: Text("Belum ada booking"));
    return ListView.builder(
      itemCount: bookingList.length,
      itemBuilder: (context, index) {
        final b = bookingList[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(b['user_id']?['nama_lengkap']?.toString() ?? 'User'),
            trailing: Icon(Icons.chevron_right),
            onTap: _navigateToManageBookings,
          ),
        );
      },
    );
  }

  Widget _buildChatPage() {
    if (userId == null || token == null) {
      return Center(child: Text("Silakan login ulang."));
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.fetchChatRooms(token!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return Center(child: Text("Gagal memuat chat."));
        }
        
        final List<dynamic> rooms = snapshot.data?['data'] ?? [];

        if (rooms.isEmpty) {
          return Center(child: Text("Belum ada pesan."));
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final roomData = rooms[index];
            
            final chatRoom = ChatRoom(
              id: roomData['_id'] ?? '',
              kostId: roomData['kost_id'],
              kostName: roomData['kost_name'] ?? 'Kost',
              ownerId: userId!,
              ownerName: userName ?? 'Admin',
              seekerId: roomData['other_user_id'],
              seekerName: roomData['other_user_name'] ?? 'User',
              messages: [], // Messages will be loaded in detail screen
              lastMessage: ChatMessage(
                id: 'last',
                roomId: roomData['_id'] ?? '',
                senderId: roomData['sender_id'] ?? '',
                senderName: '', // Not needed for list view
                receiverId: roomData['receiver_id'] ?? '',
                message: roomData['last_message'] ?? '...',
                timestamp: DateTime.tryParse(roomData['created_at'] ?? '') ?? DateTime.now(),
              ),
            );

            return ListTile(
              leading: CircleAvatar(child: Text(chatRoom.seekerName[0])),
              title: Text(chatRoom.seekerName),
              subtitle: Text(chatRoom.lastMessage?.message ?? ''),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatRoom: chatRoom,
                      currentUserId: userId!,
                      currentUserName: userName ?? 'Admin',
                    ),
                  ),
                );
                setState(() {}); 
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfilePage() {
    final bookingList = dataAll['booking'] is List
        ? (dataAll['booking'] as List)
        : [];
    final totalBookings = bookingList.length;
    final pendingBookings = bookingList
        .where((b) => b['status_booking']?.toString().toLowerCase() == 'pending')
        .length;
    
    final confirmedBookings = bookingList
        .where(
          (b) {
            final status = b['status_booking']?.toString().toLowerCase();
            return status == 'active' || status == 'confirmed' || status == 'dikonfirmasi';
          }
        )
        .length;
    final currentEmail = userEmail ?? 'email@contoh.com';

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_profileColor, Color(0xFF8B5CF6)],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      currentEmail.isNotEmpty
                          ? currentEmail[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _profileColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName ?? currentEmail.split('@')[0],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Akun Pemilik',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildProfileStatCard(
                    'Total Booking',
                    totalBookings.toString(),
                    Icons.calendar_month,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProfileStatCard(
                    'Menunggu',
                    pendingBookings.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProfileStatCard(
                    'Disetujui',
                    confirmedBookings.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fitur Pemilik',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  icon: Icons.assignment,
                  title: 'Permintaan Booking',
                  subtitle: 'Kelola permintaan booking masuk',
                  color: _profileColor,
                  badge: pendingBookings > 0 ? pendingBookings : null,
                  onTap: _navigateToBookingRequests,
                ),
                _buildMenuCard(
                  icon: Icons.home_work,
                  title: 'Kost Saya',
                  subtitle: 'Kelola daftar kost Anda',
                  color: Colors.blue,
                  onTap: () =>
                      setState(() => _selectedIndex = 1),
                ),
                _buildMenuCard(
                  icon: Icons.analytics,
                  title: 'Statistik & Laporan',
                  subtitle: 'Lihat kinerja kost Anda',
                  color: Colors.green,
                  onTap: _navigateToReportsStatistics,
                ),
                _buildMenuCard(
                  icon: Icons.payment,
                  title: 'Pembayaran',
                  subtitle: 'Riwayat pembayaran',
                  color: Colors.amber,
                  onTap: _navigateToManageBookings,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pengaturan Akun',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  icon: Icons.person,
                  title: 'Informasi Akun',
                  subtitle: 'Edit profil dan informasi pemilik',
                  color: Colors.purple,
                  onTap: _showEditProfileDialog,
                ),
                _buildMenuCard(
                  icon: Icons.notifications,
                  title: 'Notifikasi',
                  subtitle: 'Atur preferensi notifikasi',
                  color: Colors.indigo,
                  onTap: () => _showSnackBar('Pengaturan Notifikasi'),
                ),
                _buildMenuCard(
                  icon: Icons.help,
                  title: 'Bantuan & Dukungan',
                  subtitle: 'FAQ dan hubungi support',
                  color: Colors.cyan,
                  onTap: _showHelpDialog,
                ),
                _buildMenuCard(
                  icon: Icons.info,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Versi 1.0.0',
                  color: Colors.grey,
                  onTap: _showAboutDialog,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    int? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (badge != null && badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    // ... (kode dialog edit profil)
  }

  void _showHelpDialog() {
    // ... (kode dialog bantuan)
  }

  void _showAboutDialog() {
    // ... (kode dialog tentang)
  }
}
