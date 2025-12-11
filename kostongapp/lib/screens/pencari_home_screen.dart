import 'package:flutter/material.dart';
import 'package:kostong_frontend/screens/booking_screen.dart';
import 'package:kostong_frontend/screens/chat_detail_screen.dart';
import 'package:kostong_frontend/services/chat_services.dart';
import 'package:provider/provider.dart';
import '../models/profile_view_model.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'review_screen.dart';
import '../services/review_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class SeekerHomeScreen extends StatefulWidget {
  @override
  State<SeekerHomeScreen> createState() => _SeekerHomeScreenState();
}

class _SeekerHomeScreenState extends State<SeekerHomeScreen> {
  bool loading = true;
  String? token;
  Map<String, dynamic> dataAll = {};

  // Variabel lokal untuk menyimpan data favorit agar bisa dimanipulasi langsung di UI
  List<dynamic> _localFavorites = [];

  Map<String, dynamic>? userData;
  String? userName;
  Timer? _autoRefreshTimer;
  bool _isInit = true;
  int _selectedIndex = 0;

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Putra', 'Putri', 'Campur'];
  late final TextEditingController _searchController;

  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (mounted) _loadAll(showLoading: false);
    });
    _searchController = TextEditingController();

    // ✅ TAMBAH 3 BARIS INI:
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) _updateUnreadChatCount();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
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
        userData = args['data'] as Map<String, dynamic>?;
        userName =
            userData?['nama_lengkap'] ??
            userData?['name'] ??
            userData?['email'];
      }

      _loadAll();
      _isInit = false;
    }
  }

  Future<void> _openGoogleMaps(dynamic kost) async {
    // Ambil data lokasi dari kost
    final alamat = kost['alamat']?.toString() ?? '';
    final latitude = kost['latitude']?.toString() ?? '';
    final longitude = kost['longitude']?.toString() ?? '';

    Uri? mapsUri;

    // Priority 1: Gunakan koordinat GPS jika ada (lebih akurat)
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
      print('📍 Opening maps with coordinates: $latitude, $longitude');
    }
    // Priority 2: Gunakan alamat text jika tidak ada koordinat
    else if (alamat.isNotEmpty) {
      final encodedAddress = Uri.encodeComponent(alamat);
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      );
      print('📍 Opening maps with address: $alamat');
    }

    // Launch Google Maps
    if (mapsUri != null) {
      try {
        if (await canLaunchUrl(mapsUri)) {
          await launchUrl(
            mapsUri,
            mode: LaunchMode.externalApplication, // Buka di app terpisah
          );
        } else {
          if (mounted) {
            _showSnackBar('Tidak dapat membuka Google Maps', isError: true);
          }
        }
      } catch (e) {
        print('❌ Error opening maps: $e');
        if (mounted) {
          _showSnackBar('Error: ${e.toString()}', isError: true);
        }
      }
    } else {
      if (mounted) {
        _showSnackBar('Alamat kost tidak tersedia', isError: true);
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check apakah location service aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(
          'Aktifkan GPS untuk fitur lokasi terdekat',
          isError: true,
        );
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Izin lokasi ditolak', isError: true);
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Izin lokasi diblokir permanen. Aktifkan di Settings.',
          isError: true,
        );
        return null;
      }

      // Dapatkan lokasi user
      _showSnackBar('Mendapatkan lokasi Anda...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 User location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      _showSnackBar('Gagal mendapatkan lokasi', isError: true);
      return null;
    }
  }

  /// Menghitung jarak antara 2 koordinat GPS (dalam km)
  /// Menggunakan Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radius bumi dalam km

    double dLat = _degreeToRadian(lat2 - lat1);
    double dLon = _degreeToRadian(lon2 - lon1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreeToRadian(lat1)) *
            math.cos(_degreeToRadian(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;

    return distance; // dalam km
  }

  /// Convert degree ke radian
  double _degreeToRadian(double degree) {
    return degree * math.pi / 180;
  }

  /// Sorting kost berdasarkan jarak terdekat dari user
  Future<void> _sortByNearestLocation() async {
    // Dapatkan lokasi user
    Position? userPosition = await _getCurrentLocation();
    if (userPosition == null) return;

    setState(() {
      loading = true;
    });

    try {
      final kostList = dataAll['kost'] is List ? dataAll['kost'] as List : [];

      // Hitung jarak untuk setiap kost
      List<Map<String, dynamic>> kostsWithDistance = [];

      for (var kost in kostList) {
        // Parse koordinat kost
        double? kostLat = double.tryParse(kost['latitude']?.toString() ?? '');
        double? kostLon = double.tryParse(kost['longitude']?.toString() ?? '');

        if (kostLat != null && kostLon != null) {
          // Hitung jarak
          double distance = _calculateDistance(
            userPosition.latitude,
            userPosition.longitude,
            kostLat,
            kostLon,
          );

          // Tambahkan field distance ke kost
          Map<String, dynamic> kostWithDistance = Map.from(kost);
          kostWithDistance['distance'] = distance;
          kostsWithDistance.add(kostWithDistance);

          print('📍 ${kost['nama_kost']}: ${distance.toStringAsFixed(2)} km');
        } else {
          // Kost tanpa koordinat, taruh di akhir
          Map<String, dynamic> kostWithDistance = Map.from(kost);
          kostWithDistance['distance'] = double.infinity;
          kostsWithDistance.add(kostWithDistance);
        }
      }

      // Sort berdasarkan jarak (terdekat dulu)
      kostsWithDistance.sort((a, b) {
        return a['distance'].compareTo(b['distance']);
      });

      // Update dataAll dengan list yang sudah di-sort
      setState(() {
        dataAll['kost'] = kostsWithDistance;
        loading = false;
      });

      _showSnackBar('Menampilkan ${kostsWithDistance.length} kost terdekat');
    } catch (e) {
      print('❌ Error sorting by location: $e');
      setState(() {
        loading = false;
      });
      _showSnackBar('Gagal mengurutkan berdasarkan lokasi', isError: true);
    }
  }

  void _updateUnreadChatCount() {
    final userId =
        userData?['_id']?.toString() ?? userData?['id']?.toString() ?? '0';

    final unreadCount = ChatService.getUnreadMessageCount(userId);

    if (mounted && unreadCount != _unreadChatCount) {
      setState(() {
        _unreadChatCount = unreadCount;
      });
    }
  }

  void _openChat(dynamic kost) {
    // Ambil data yang diperlukan dari kost
    final kostId = kost['_id']?.toString() ?? kost['id']?.toString() ?? '';
    final kostName = kost['nama_kost']?.toString() ?? 'Kost';
    final ownerId = kost['pemilik_id']?.toString() ?? '0';
    final ownerName = kost['pemilik_nama']?.toString() ?? 'Pemilik Kost';

    // Validasi data
    if (kostId.isEmpty) {
      _showSnackBar('Data kost tidak lengkap', isError: true);
      return;
    }

    // Dapatkan ID user dari userData
    final userId =
        userData?['_id']?.toString() ?? userData?['id']?.toString() ?? '0';

    print('💬 Opening chat - User: $userId, Owner: $ownerId');

    // Create atau get chat room
    final chatRoom = ChatService.getOrCreateChatRoom(
      kostId: kostId,
      kostName: kostName,
      ownerId: ownerId,
      ownerName: ownerName,
      seekerId: userId,
      seekerName: userName ?? 'User',
    );

    // Navigate ke chat detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatRoom: chatRoom,
          currentUserId: userId,
          currentUserName: userName ?? 'User',
        ),
      ),
    );
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
        // Reset data favorit lokal saat refresh agar sesuai database
        _localFavorites = [];
        // Jika API favorit mengembalikan data, masukkan ke localFavorites
        if (dataAll['favorit'] is List) {
          // _localFavorites = List.from(dataAll['favorit']); // Uncomment jika ingin sync dengan API
        }
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

  // Fungsi untuk Toggle Favorit
  void _toggleFavorite(dynamic kost) {
    setState(() {
      final index = _localFavorites.indexWhere((item) {
        // Cek ID, handle format _id mongo atau id biasa
        final itemId = item['_id']?.toString() ?? item['id']?.toString();
        final kostId = kost['_id']?.toString() ?? kost['id']?.toString();
        return itemId == kostId;
      });

      if (index != -1) {
        // Jika sudah ada, hapus (Unfavorite)
        _localFavorites.removeAt(index);
        _showSnackBar("${kost['nama_kost']} dihapus dari favorit");
      } else {
        // Jika belum ada, tambahkan
        _localFavorites.add(kost);
        _showSnackBar("${kost['nama_kost']} ditambahkan ke favorit");
      }
    });
  }

  bool _isFavorite(dynamic kost) {
    return _localFavorites.any((item) {
      final itemId = item['_id']?.toString() ?? item['id']?.toString();
      final kostId = kost['_id']?.toString() ?? kost['id']?.toString();
      return itemId == kostId;
    });
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
          : ChangeNotifierProvider(
              create: (_) => ProfileTabViewModel(userData),
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomePage(),
                  _buildFavoritePage(), // Halaman Favorit
                  _buildBookingPage(),
                  _buildChatPage(),
                  ProfileTabPage(),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 3) {
            _unreadChatCount = 0;
          }
        },
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
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.chat_bubble_outline),
                if (_unreadChatCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _unreadChatCount > 99 ? '99+' : '$_unreadChatCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  // --- HOME PAGE ---
  Widget _buildHomePage() {
    final kostList = dataAll['kost'] is List ? dataAll['kost'] as List : [];
    final query = _searchQuery.trim().toLowerCase();

    final filteredKost = kostList.where((kost) {
      if (query.isNotEmpty) {
        final namaKost = kost['nama_kost']?.toString().toLowerCase() ?? '';
        final kota = kost['alamat'] is Map
            ? (kost['alamat']['kota']?.toString().toLowerCase() ?? '')
            : '';
        if (!namaKost.contains(query) && !kota.contains(query)) return false;
      }
      if (_selectedCategory != 'Semua') {
        final tipeKost = kost['tipe_kost']?.toString() ?? '';
        if (tipeKost.toLowerCase() != _selectedCategory.toLowerCase())
          return false;
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${userName ?? 'Pencari Kost'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4facfe),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari nama kost atau lokasi...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // Tombol Filter Lokasi Terdekat
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sortByNearestLocation,
                    icon: Icon(Icons.near_me, size: 18),
                    label: Text('Terdekat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4facfe),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Tombol Trending
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSnackBar('Menampilkan kost trending...');
                    },
                    icon: Icon(Icons.explore, size: 18),
                    label: Text('Trending'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF4facfe),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Color(0xFF4facfe), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filter Chips
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: Color(0xFF4facfe),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[200],
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (bool selected) {
                        if (selected)
                          setState(() => _selectedCategory = category);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Grid Kost
          Expanded(
            child: filteredKost.isEmpty
                ? _buildEmptyState("Tidak ada kost ditemukan")
                : _buildGridList(filteredKost),
          ),
        ],
      ),
    );
  }

  // --- FAVORITE PAGE ---
  Widget _buildFavoritePage() {
    return RefreshIndicator(
      onRefresh: () async {},
      child: Column(
        children: [
          AppBar(
            title: Text(
              "Favorit Saya",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          Expanded(
            child: _localFavorites.isEmpty
                ? _buildEmptyState(
                    "Belum ada favorit",
                    icon: Icons.favorite_border,
                  )
                : _buildGridList(_localFavorites),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: EMPTY STATE ---
  Widget _buildEmptyState(
    String message, {
    IconData icon = Icons.home_work_outlined,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: GRID BUILDER (RESPONSIF) ---
  Widget _buildGridList(List<dynamic> dataList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth >= 1100) {
          // Desktop Besar
          crossAxisCount = 4;
          childAspectRatio = 0.8;
        } else if (constraints.maxWidth >= 800) {
          // Tablet Landscape / Desktop Kecil
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else if (constraints.maxWidth >= 600) {
          // Tablet Portrait
          crossAxisCount = 2;
          childAspectRatio = 0.9;
        } else {
          // Mobile
          crossAxisCount = 1;
          childAspectRatio = 1.2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: dataList.length,
          itemBuilder: (context, index) {
            return _buildKostCard(dataList[index]);
          },
        );
      },
    );
  }

  // --- CARD KOST (UPDATED) ---
  Widget _buildKostCard(dynamic kost) {
    String imageUrl = 'https://via.placeholder.com/400x300?text=No+Image';
    if (kost['foto_kost'] != null && (kost['foto_kost'] as List).isNotEmpty) {
      imageUrl = (kost['foto_kost'] as List)[0];
    }

    String namaKost = kost['nama_kost'] ?? 'Nama Kost';
    String tipeKost = kost['tipe_kost'] ?? 'Campur';
    String kota = kost['alamat'] is Map
        ? (kost['alamat']['kota'] ?? '')
        : (kost['alamat'] ?? 'Lokasi tidak diketahui');
    double rating = (kost['rating'] ?? 0).toDouble();
    final distance = kost['distance'];
    final hasDistance = distance != null && distance != double.infinity;

    // Ambil harga dari field 'harga' atau 'harga_per_bulan'
    int harga = kost['harga'] ?? kost['harga_per_bulan'] ?? 0;

    String deskripsi = kost['deskripsi'] ?? '';
    bool isFav = _isFavorite(kost);

    return GestureDetector(
      onTap: () => _showKostDetail(kost),
      child: Container(
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
            // Bagian Foto & Badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasDistance)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Badge Tipe Kost
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tipeKost,
                        style: TextStyle(
                          color: Color(0xFF4facfe),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Tombol Love (Favorit)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => _toggleFavorite(kost),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bagian Info Text
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Stack items from top
                  children: [
                    Text(
                      namaKost,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kota.isNotEmpty ? kota : 'Lokasi belum diatur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Harga ditampilkan di sini (dibawah lokasi)
                    Text(
                      harga > 0 ? _formatCurrency(harga) : 'Hubungi Pemilik',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4facfe),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deskripsi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
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

  String _formatCurrency(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}/bln";
  }

  Widget _buildBookingPage() {
    final bookingList = dataAll['booking'] is List
        ? dataAll['booking'] as List
        : [];
    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: bookingList.isEmpty
          ? _buildEmptyState(
              "Belum ada booking",
              icon: Icons.event_note_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookingList.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = bookingList[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.home, color: Color(0xFF4facfe)),
                    title: Text(b['nama_kost']?.toString() ?? 'Kost'),
                    subtitle: Text(
                      b['tanggal']?.toString() ??
                          b['status']?.toString() ??
                          '-',
                    ),
                    onTap: () => _showKostDetail(b),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildChatPage() {
    final userId =
        userData?['_id']?.toString() ?? userData?['id']?.toString() ?? '0';

    final chatRooms = ChatService.getChatRoomsForUser(userId);

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _updateUnreadChatCount();
        });
      },
      child: Column(
        children: [
          AppBar(
            title: Text(
              "Pesan",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          Expanded(
            child: chatRooms.isEmpty
                ? _buildEmptyState(
                    "Belum ada percakapan",
                    icon: Icons.chat_bubble_outline,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatRooms.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final chatRoom = chatRooms[index];
                      final unreadCount = chatRoom.unreadCount;

                      return Card(
                        elevation: unreadCount > 0 ? 2 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(
                                  0xFF4facfe,
                                ).withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF4facfe),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chatRoom.ownerName,
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                chatRoom.kostName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4facfe),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  chatRoom: chatRoom,
                                  currentUserId: userId,
                                  currentUserName: userName ?? 'User',
                                ),
                              ),
                            ).then((_) {
                              // Refresh unread count setelah kembali dari chat
                              _updateUnreadChatCount();
                              setState(() {});
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Format timestamp untuk chat preview
  String _formatChatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Hari ini - tampilkan jam
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showKostDetail(dynamic kost) {
    String imageUrl = 'https://via.placeholder.com/400x300?text=No+Image';
    if (kost['foto_kost'] != null && (kost['foto_kost'] as List).isNotEmpty) {
      imageUrl = (kost['foto_kost'] as List)[0];
    }

    // Ambil harga untuk detail view juga
    int harga = kost['harga'] ?? kost['harga_per_bulan'] ?? 0;
    bool isFav = _isFavorite(kost);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
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
                          // Image Preview di Detail
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  imageUrl,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: InkWell(
                                  onTap: () {
                                    _toggleFavorite(kost);
                                    setModalState(() {
                                      isFav = !isFav;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (kost['alamat'] is Map
                                              ? kost['alamat']['kota']
                                              : kost['alamat'])
                                          ?.toString() ??
                                      '-',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          Divider(),
                          SizedBox(height: 20),

                          // ✅ SINKRONISASI: Google Maps Integration
                          Text(
                            "Lokasi Maps",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF4facfe).withOpacity(0.1),
                                  Color(0xFF00f2fe).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF4facfe).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Tutup bottom sheet dulu
                                  Navigator.pop(builderContext);
                                  // Tutup bottom sheet dulu menggunakan context dari builder-nya
                                  Navigator.pop(builderContext);
                                  // Buka Google Maps
                                  _openGoogleMaps(kost);
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF4facfe),
                                            Color(0xFF00f2fe),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.map,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "Buka di Google Maps",
                                      style: TextStyle(
                                        color: Color(0xFF4facfe),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Lihat lokasi & petunjuk arah",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 24),
                          Divider(),
                          SizedBox(height: 20),

                          // ✅ SINKRONISASI: Contact Owner dengan Chat Integration
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF4facfe).withOpacity(0.1),
                                  Color(0xFF00f2fe).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF4facfe).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF4facfe),
                                            Color(0xFF00f2fe),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        radius: 28,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Pemilik Kost",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            kost['pemilik_nama'] ??
                                                'Bapak/Ibu Kost',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Tombol Chat & Telepon
                                Row(
                                  children: [
                                    // Tombol Chat (Primary)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(builderContext);
                                          _openChat(kost);
                                        },
                                        icon: Icon(
                                          Icons.chat_bubble_outline,
                                          size: 18,
                                        ),
                                        label: Text('Chat'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF4facfe),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),

                                    // Tombol Telepon (Secondary)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          _showSnackBar(
                                            'Menghubungi ${kost['no_telepon'] ?? 'Pemilik'}...',
                                          );
                                        },
                                        icon: Icon(Icons.phone, size: 18),
                                        label: Text('Telepon'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Color(0xFF4facfe),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          side: BorderSide(
                                            color: Color(0xFF4facfe),
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),
                          Divider(),
                          SizedBox(height: 20),
                          _buildDetailRow(
                            'Harga',
                            harga > 0 ? _formatCurrency(harga) : '-',
                          ),
                          _buildDetailRow('Tipe', kost['tipe_kost']),

                          if (kost['fasilitas_umum'] != null)
                            _buildDetailRow(
                              'Fasilitas',
                              (kost['fasilitas_umum'] as List).join(', '),
                            ),

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
                            kost['deskripsi']?.toString() ??
                                'Tidak ada deskripsi',
                            style: TextStyle(color: Colors.grey[700]),
                          ),

                          SizedBox(height: 24),
                          _buildReviewSection(kost),

                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingScreen(
                                      kostData:
                                          kost, // Mengirim data kost yang sedang dipilih
                                    ),
                                  ),
                                );
                                if (result == 'booking_success') {
                                  _loadAll(showLoading: false);
                                  setState(() {
                                    _selectedIndex = 2;
                                  });
                                }
                                _showSnackBar(
                                  'Booking berhasil! Cek halaman booking untuk detail.',
                                );
                                // Pindah ke tab booking
                                setState(() {
                                  _selectedIndex = 2; // Index 2 = Tab Booking
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4facfe),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Color(0xFF4facfe).withOpacity(0.4),
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
          );
        },
      ),
    );
  }

  Widget _buildReviewSection(dynamic kost) {
    final String kostId =
        kost['id']?.toString() ?? kost['_id']?.toString() ?? '0';

    final reviews = ReviewService.getReviewsForKost(kostId);
    final firstReview = reviews.isNotEmpty ? reviews.first : null;

    final avgRating = reviews.isNotEmpty
        ? (reviews.map((e) => e.rating).reduce((a, b) => a + b) /
              reviews.length)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ulasan Penghuni',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  ' (${reviews.length})',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        if (firstReview != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(firstReview.userImage),
                      radius: 12,
                      backgroundColor: Colors.grey[300],
                    ),
                    SizedBox(width: 8),
                    Text(
                      firstReview.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Spacer(),
                    Text(
                      firstReview.date,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  firstReview.content,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        else
          Text(
            'Belum ada ulasan untuk kost ini.',
            style: TextStyle(color: Colors.grey),
          ),

        SizedBox(height: 12),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewScreen(kostId: kostId),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lihat Semua Ulasan',
                style: TextStyle(
                  color: Color(0xFF4facfe),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, color: Color(0xFF4facfe), size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
}

// --- Profile Page (Tetap sama) ---
class ProfileTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileTabViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Saya'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUserInfo(context, viewModel.user),
          const SizedBox(height: 24),
          _buildNavigationTile(
            context,
            title: 'Edit Data Pribadi',
            icon: Icons.person_outline,
            onTap: () {
              final vm = context.read<ProfileTabViewModel>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(viewModel: vm),
                ),
              );
            },
          ),
          _buildNavigationTile(
            context,
            title: 'Pengaturan & Privasi',
            icon: Icons.settings_outlined,
            onTap: () {
              final vm = context.read<ProfileTabViewModel>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(viewModel: vm),
                ),
              );
            },
          ),
          _buildNavigationTile(
            context,
            title: 'Riwayat Transaksi',
            icon: Icons.history,
            onTap: () {
              final vm = context.read<ProfileTabViewModel>();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryScreen(viewModel: vm)),
              );
            },
          ),
          const Divider(),
          _buildNavigationTile(
            context,
            title: 'Logout',
            icon: Icons.logout,
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, UserProfile user) {
    final vm = context.watch<ProfileTabViewModel>();
    final gender = vm.selectedGender ?? '-';
    final date = vm.selectedDate;
    String formattedDate = '-';
    if (date != null) {
      final d = date is DateTime ? date : null;
      if (d != null) formattedDate = '${d.day}/${d.month}/${d.year}';
    }

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.profileImageUrl),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(gender, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(width: 12),
              Icon(Icons.cake, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(formattedDate, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.grey[700];
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Anda yakin ingin logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Ya, Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              },
            ),
          ],
        );
      },
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  final ProfileTabViewModel viewModel;
  const EditProfileScreen({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Data Pribadi'),
          backgroundColor: const Color.fromARGB(255, 96, 96, 96),
        ),
        body: Consumer<ProfileTabViewModel>(
          builder: (context, vm, _) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                TextFormField(
                  controller: vm.fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: vm.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: vm.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jenis Kelamin',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Laki-laki'),
                            value: 'Laki-laki',
                            groupValue: vm.selectedGender,
                            onChanged: (val) => vm.setGender(val),
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF4facfe),
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Perempuan'),
                            value: 'Perempuan',
                            groupValue: vm.selectedGender,
                            onChanged: (val) => vm.setGender(val),
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color.fromARGB(
                              255,
                              239,
                              79,
                              254,
                            ),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal Lahir',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: vm.selectedDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          vm.setDate(pickedDate);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(255, 32, 167, 240)!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vm.selectedDate == null
                                  ? 'Pilih tanggal'
                                  : '${vm.selectedDate!.day}/${vm.selectedDate!.month}/${vm.selectedDate!.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today_outlined),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      vm.saveProfile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perubahan profil disimpan'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4facfe),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
