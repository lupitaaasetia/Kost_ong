import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

class SeekerHomeScreen extends StatefulWidget {
  @override
  State<SeekerHomeScreen> createState() => _SeekerHomeScreenState();
}

class _SeekerHomeScreenState extends State<SeekerHomeScreen> {
  bool loading = true;
  String? token;
  Map<String, dynamic> dataAll = {};
  String? userName;
  Timer? _autoRefreshTimer;
  bool _isInit = true;
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (mounted) _loadAll(showLoading: false);
    });
  }

  @override
  void dispose() {
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
      ApiService.fetchFavorit(token),
      ApiService.fetchRiwayat(token),
    ]);

    final keys = ['kost', 'booking', 'favorit', 'riwayat'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4facfe)),
                  SizedBox(height: 16),
                  Text('Memuat data...'),
                ],
              ),
            )
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomePage(),
                _buildFavoritePage(),
                _buildBookingPage(),
                _buildProfilePage(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF4facfe),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Booking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    final kostList = dataAll['kost'] is List ? dataAll['kost'] as List : [];
    final filteredKost = kostList.where((kost) {
      if (_searchQuery.isEmpty) return true;
      final namaKost = kost['nama_kost']?.toString().toLowerCase() ?? '';
      final alamat = kost['alamat']?.toString().toLowerCase() ?? '';
      return namaKost.contains(_searchQuery.toLowerCase()) ||
          alamat.contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF4facfe),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 60, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${userName ?? 'Pencari Kost'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Temukan kost impian Anda',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari kost...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF4facfe),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: filteredKost.isEmpty
                ? SliverFillRemaining(
                    child: Center(
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
                            'Tidak ada kost tersedia',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final kost = filteredKost[index];
                      return _buildKostCard(kost);
                    }, childCount: filteredKost.length),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKostCard(dynamic kost) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showKostDetail(kost),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.home_work,
                      size: 60,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          color: Color(0xFF4facfe),
                        ),
                        onPressed: () {
                          // TODO: Add to favorites
                          _showSnackBar('Ditambahkan ke favorit');
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kost['status']?.toString() ?? 'Tersedia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kost['nama_kost']?.toString() ?? 'Kost',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          kost['alamat']?.toString() ?? '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF4facfe).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kost['tipe_kamar']?.toString() ?? 'Tipe',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4facfe),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Rp ${kost['harga']?.toString() ?? '0'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4facfe),
                        ),
                      ),
                      Text(
                        '/bulan',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  void _showKostDetail(dynamic kost) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.home_work,
                            size: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        kost['nama_kost']?.toString() ?? 'Kost',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              kost['alamat']?.toString() ?? '-',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildDetailRow('Harga', 'Rp ${kost['harga']}/bulan'),
                      _buildDetailRow('Tipe Kamar', kost['tipe_kamar']),
                      _buildDetailRow('Fasilitas', kost['fasilitas']),
                      _buildDetailRow('Status', kost['status']),
                      SizedBox(height: 24),
                      Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        kost['deskripsi']?.toString() ?? 'Tidak ada deskripsi',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showSnackBar('Booking berhasil dibuat');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4facfe),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Booking Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritePage() {
    final favoritList = dataAll['favorit'] is List
        ? dataAll['favorit'] as List
        : [];

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: favoritList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada favorit',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: favoritList.length,
              itemBuilder: (context, index) {
                final favorit = favoritList[index];
                return _buildKostCard(favorit);
              },
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.home_work, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['nama_kost']?.toString() ?? 'Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        booking['tanggal_booking']?.toString() ?? '-',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF4facfe).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['status']?.toString() ?? 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4facfe),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            backgroundColor: Color(0xFF4facfe),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            userName ?? 'Pencari Kost',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Pencari Kost', style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 32),
          _buildProfileMenuItem(Icons.person, 'Edit Profil', () {}),
          _buildProfileMenuItem(Icons.history, 'Riwayat', () {}),
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
          color: isDestructive ? Colors.red : Color(0xFF4facfe),
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
