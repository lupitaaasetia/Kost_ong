import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

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
  late AnimationController _animController;
  Timer? _autoRefreshTimer;
  bool _isInit = true;
  int _selectedIndex = 0;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    _autoRefreshTimer?.cancel();
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
      }

      _loadAll();
      _isInit = false;
    }
  }

  Future<void> _loadAll({bool showLoading = true}) async {
    if (showLoading) {
      if (mounted) setState(() => loading = true);
      _animController.forward(from: 0);
    }

    if (token == null) {
      if (mounted) {
        setState(() => loading = false);
        _showSnackBar(
          'Token tidak ditemukan, silakan login ulang.',
          isError: true,
        );
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/');
        });
      }
      return;
    }

    final futures = await Future.wait([
      ApiService.fetchKost(token),
      ApiService.fetchBooking(token),
      ApiService.fetchPembayaran(token),
      ApiService.fetchReview(token),
    ]);

    final keys = ['kost', 'booking', 'pembayaran', 'review'];
    final tmp = <String, dynamic>{};

    for (int i = 0; i < keys.length; i++) {
      final r = futures[i] as Map<String, dynamic>;
      if (r['success'] == true) {
        tmp[keys[i]] = r['data'];
      } else {
        tmp[keys[i]] = {'error': r['message'] ?? 'gagal'};

        if (r['requiresLogin'] == true) {
          if (mounted) {
            _showSnackBar(
              'Sesi berakhir. Silakan login kembali.',
              isError: true,
            );
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            });
          }
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        dataAll = tmp;
        loading = false;
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
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _logout() {
    setState(() {
      token = null;
    });
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Dashboard Pemilik',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF667eea)),
                  SizedBox(height: 16),
                  Text('Memuat data...'),
                ],
              ),
            )
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboardPage(),
                _buildKostPage(),
                _buildBookingPage(),
                _buildProfilePage(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF667eea),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Kost Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Booking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    final kostCount = dataAll['kost'] is List
        ? (dataAll['kost'] as List).length
        : 0;
    final bookingCount = dataAll['booking'] is List
        ? (dataAll['booking'] as List).length
        : 0;
    final reviewCount = dataAll['review'] is List
        ? (dataAll['review'] as List).length
        : 0;

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      userName ?? 'Pemilik Kost',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Kelola properti kost Anda dengan mudah',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Statistics Cards
              Text(
                'Statistik',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Kost',
                      kostCount.toString(),
                      Icons.home_work,
                      Color(0xFF4facfe),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Booking',
                      bookingCount.toString(),
                      Icons.event_note,
                      Color(0xFFf093fb),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Review',
                      reviewCount.toString(),
                      Icons.star,
                      Color(0xFFfeca57),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pendapatan',
                      'Rp 0',
                      Icons.attach_money,
                      Color(0xFF48dbfb),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Quick Actions
              Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Tambah Kost',
                      Icons.add_home,
                      Color(0xFF667eea),
                      () {
                        // TODO: Navigate to add kost
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Lihat Booking',
                      Icons.list_alt,
                      Color(0xFF764ba2),
                      () {
                        setState(() => _selectedIndex = 2);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKostPage() {
    final kostList = dataAll['kost'] is List ? dataAll['kost'] as List : [];

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: kostList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada kost',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tambahkan kost pertama Anda',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add kost
                    },
                    icon: Icon(Icons.add),
                    label: Text('Tambah Kost'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: kostList.length,
              itemBuilder: (context, index) {
                final kost = kostList[index];
                return _buildKostCard(kost);
              },
            ),
    );
  }

  Widget _buildKostCard(dynamic kost) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.home_work, color: Colors.white, size: 30),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kost['nama_kost']?.toString() ?? 'Kost',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        kost['alamat']?.toString() ?? '-',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      value: 'edit',
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      value: 'delete',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('Harga', kost['harga']?.toString() ?? '-'),
                SizedBox(width: 8),
                _buildInfoChip('Status', kost['status']?.toString() ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF667eea).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF667eea),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBookingPage() {
    final bookingList = dataAll['booking'] is List
        ? dataAll['booking'] as List
        : [];

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: bookingList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada booking',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: bookingList.length,
              itemBuilder: (context, index) {
                final booking = bookingList[index];
                return _buildBookingCard(booking);
              },
            ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF667eea),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(booking['nama_pemesan']?.toString() ?? 'Booking'),
        subtitle: Text(booking['tanggal_booking']?.toString() ?? '-'),
        trailing: Chip(
          label: Text(
            booking['status']?.toString() ?? 'Pending',
            style: TextStyle(fontSize: 11),
          ),
          backgroundColor: Color(0xFF667eea).withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF667eea),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            userName ?? 'Pemilik Kost',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Pemilik Kost', style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 32),
          _buildProfileMenuItem(Icons.person, 'Edit Profil', () {}),
          _buildProfileMenuItem(Icons.settings, 'Pengaturan', () {}),
          _buildProfileMenuItem(Icons.help, 'Bantuan', () {}),
          _buildProfileMenuItem(
            Icons.logout,
            'Keluar',
            () => Navigator.pushReplacementNamed(context, '/'),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Color(0xFF667eea),
        ),
        title: Text(
          title,
          style: TextStyle(color: isDestructive ? Colors.red : Colors.black87),
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
