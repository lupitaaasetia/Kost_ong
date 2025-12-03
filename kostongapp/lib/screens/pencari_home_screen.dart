import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart'; // Uncomment jika ingin fitur buka peta/telpon
import '../models/profile_view_model.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'review_screen.dart';
import '../services/review_service.dart';

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

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (mounted) _loadAll(showLoading: false);
    });
    _searchController = TextEditingController();
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
                  ProfileTabPage(),
                ],
              ),
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

  // --- HOME PAGE ---
  Widget _buildHomePage() {
    final kostList = dataAll['kost'] is List ? dataAll['kost'] as List : [];
    final query = _searchQuery.trim().toLowerCase();
    
    final filteredKost = kostList.where((kost) {
      if (query.isNotEmpty) {
        final namaKost = kost['nama_kost']?.toString().toLowerCase() ?? '';
        final kota = kost['alamat'] is Map ? (kost['alamat']['kota']?.toString().toLowerCase() ?? '') : '';
        if (!namaKost.contains(query) && !kota.contains(query)) return false;
      }
      if (_selectedCategory != 'Semua') {
        final tipeKost = kost['tipe_kost']?.toString() ?? '';
        if (tipeKost.toLowerCase() != _selectedCategory.toLowerCase()) return false;
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4facfe)),
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[200],
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (bool selected) {
                        if (selected) setState(() => _selectedCategory = category);
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
            title: Text("Favorit Saya", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          Expanded(
            child: _localFavorites.isEmpty
                ? _buildEmptyState("Belum ada favorit", icon: Icons.favorite_border)
                : _buildGridList(_localFavorites),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: EMPTY STATE ---
  Widget _buildEmptyState(String message, {IconData icon = Icons.home_work_outlined}) {
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
    String kota = kost['alamat'] is Map ? (kost['alamat']['kota'] ?? '') : (kost['alamat'] ?? 'Lokasi tidak diketahui');
    double rating = (kost['rating'] ?? 0).toDouble();
    
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  // Badge Tipe Kost
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  mainAxisAlignment: MainAxisAlignment.start, // Stack items from top
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
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kota.isNotEmpty ? kota : 'Lokasi belum diatur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        )
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
    final bookingList = dataAll['booking'] is List ? dataAll['booking'] as List : [];
    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: bookingList.isEmpty
          ? _buildEmptyState("Belum ada booking", icon: Icons.event_note_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookingList.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = bookingList[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.home, color: Color(0xFF4facfe)),
                    title: Text(b['nama_kost']?.toString() ?? 'Kost'),
                    subtitle: Text(b['tanggal']?.toString() ?? b['status']?.toString() ?? '-'),
                    onTap: () => _showKostDetail(b),
                  ),
                );
              },
            ),
    );
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
                                      child: Icon(Icons.broken_image));
                                },
                              ),
                            ),
                            Positioned(
                              top: 10, 
                              right: 10,
                              child: InkWell(
                                onTap: (){
                                  _toggleFavorite(kost);
                                  setModalState((){
                                    isFav = !isFav;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.red : Colors.grey,
                                  ),
                                ),
                              ),
                            )
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
                            Icon(Icons.location_on, size: 18, color: Colors.grey),
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
                        SizedBox(height: 20),
                        _buildDetailRow(
                            'Harga',
                            harga > 0 
                                ? _formatCurrency(harga)
                                : '-'),
                        _buildDetailRow('Tipe', kost['tipe_kost']),

                        if (kost['fasilitas_umum'] != null)
                          _buildDetailRow('Fasilitas',
                              (kost['fasilitas_umum'] as List).join(', ')),

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
                        _buildReviewSection(kost),

                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final viewModel =
                                  builderContext.read<ProfileTabViewModel>();
                              viewModel.addNewTransaction(kost);
                              Navigator.pop(context);
                              _showSnackBar(
                                  'Booking berhasil ditambahkan ke riwayat transaksi.');
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
        );}
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(' (${reviews.length})',
                    style: TextStyle(color: Colors.grey)),
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
                    Text(firstReview.userName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Spacer(),
                    Text(firstReview.date,
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
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
          Text('Belum ada ulasan untuk kost ini.',
              style: TextStyle(color: Colors.grey)),

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
                    builder: (_) => EditProfileScreen(viewModel: vm)),
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
                    builder: (_) => SettingsScreen(viewModel: vm)),
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
                MaterialPageRoute(
                    builder: (_) => HistoryScreen(viewModel: vm)),
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
            style: Theme.of(context)
                .textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
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

  Widget _buildNavigationTile(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : Colors.grey[700];
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(color: color, fontWeight: FontWeight.w500)),
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
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/', (Route<dynamic> route) => false);
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
                    Text('Jenis Kelamin',
                        style: Theme.of(context).textTheme.bodyLarge),
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
                            activeColor:
                                const Color.fromARGB(255, 239, 79, 254),
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
                    Text('Tanggal Lahir',
                        style: Theme.of(context).textTheme.bodyLarge),
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
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color.fromARGB(255, 32, 167, 240)!),
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