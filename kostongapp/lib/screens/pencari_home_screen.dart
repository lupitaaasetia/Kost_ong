import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile_view_model.dart';
import '../services/api_service.dart';
import '../widgets/responsive_searchbar.dart';
import 'dart:async';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'review_screen.dart';
import '../models/review_model.dart'; 

class SeekerHomeScreen extends StatefulWidget {
  @override
  State<SeekerHomeScreen> createState() => _SeekerHomeScreenState();
}

class _SeekerHomeScreenState extends State<SeekerHomeScreen> {
  bool loading = true;
  String? token;
  Map<String, dynamic> dataAll = {};
  Map<String, dynamic>? userData;
  String? userName;
  Timer? _autoRefreshTimer;
  bool _isInit = true;
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _selectedCategory = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (mounted) _loadAll(showLoading: false);
    });
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (!mounted) return;
      final val = _searchController.text;
      if (val != _searchQuery) setState(() => _searchQuery = val);
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
          : ChangeNotifierProvider(
              create: (_) => ProfileTabViewModel(userData),
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomePage(),
                  _buildFavoritePage(),
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

  Widget _buildHomePage() {
    final kostList = dataAll['kost'] is List ? dataAll['kost'] as List : [];
    final query = _searchQuery.trim().toLowerCase();
    
    final filteredKost = kostList.where((kost) {
      if (query.isNotEmpty) {
        final namaKost = kost['nama_kost']?.toString().toLowerCase() ?? '';
        final alamat = kost['alamat']?.toString().toLowerCase() ?? '';
        if (!namaKost.contains(query) && !alamat.contains(query)) return false;
      }
      if (_selectedCategory.isNotEmpty) {
        final tipeKost = kost['tipe_kost']?.toString() ?? '';
        if (!tipeKost.contains(_selectedCategory)) return false;
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: CustomScrollView(
        slivers: [
          // Header Biru dengan Padding yang disesuaikan
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(32, 60, 32, 40),
              color: Color(0xFF4facfe),
              margin: EdgeInsets.only(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${userName ?? 'Pencari Kost'}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Temukan kost impian Anda',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ResponsiveSearchBar(
                controller: _searchController,
                onSearch: (value) {
                  if (!mounted) return;
                  setState(() => _searchQuery = value);
                },
                onCategorySelect: (category) {
                  if (!mounted) return;
                  setState(() {
                    _selectedCategory = category;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                onExplore: () {
                  _showSnackBar('Menampilkan kost trending...');
                },
                onSchedule: () {
                  _showSnackBar('Buka jadwal kunjungan...');
                },
                onFindLocation: () {
                  _showSnackBar('Buka peta lokasi kost...');
                },
              ),
            ),
          ),
          
          // Filter Category (Jika aktif)
          if (_selectedCategory.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kategori: $_selectedCategory',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = '');
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.clear, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Hapus',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
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
            
          // List Kost
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: filteredKost.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
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
                              color: Color.fromARGB(255, 70, 179, 242),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _selectedCategory.isNotEmpty
                                ? 'Coba ubah kategori'
                                : 'Coba dengan kata kunci lain',
                            style: TextStyle(
                              fontSize: 13,
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
                          _showSnackBar('Ditambahkan ke favorit');
                        },
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
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
  
  Widget _buildFavoritePage() {
    final favList = dataAll['favorit'] is List ? dataAll['favorit'] as List : [];

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: favList.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border, size: 72, color: Colors.grey[400]),
                      SizedBox(height: 12),
                      Text('Belum ada favorit', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favList.length,
              itemBuilder: (context, index) {
                final k = favList[index];
                return _buildKostCard(k);
              },
            ),
    );
  }

  Widget _buildBookingPage() {
    final bookingList = dataAll['booking'] is List ? dataAll['booking'] as List : [];

    return RefreshIndicator(
      onRefresh: () => _loadAll(showLoading: false),
      child: bookingList.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_note_outlined, size: 72, color: Colors.grey[400]),
                      SizedBox(height: 12),
                      Text('Belum ada booking', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                ),
              ],
            )
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) => DraggableScrollableSheet(
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
                      
                      // --- SECTION ULASAN YANG DITAMBAHKAN ---
                      SizedBox(height: 24),
                      _buildReviewSection(kost),
                      // ---------------------------------------

                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Get the view model from the context of the main screen
                            final viewModel = context.read<ProfileTabViewModel>();
                            // Add the new transaction
                            viewModel.addNewTransaction(kost);
                            // Close the bottom sheet
                            Navigator.pop(context);
                            // Show a confirmation message
                            _showSnackBar('Booking berhasil ditambahkan ke riwayat transaksi.');
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

  // WIDGET UNTUK REVIEW SECTION (Updated dengan ReviewService)
  Widget _buildReviewSection(dynamic kost) {
    // Ambil ID kost secara aman
    final String kostId = kost['id']?.toString() ?? kost['_id']?.toString() ?? '0';
    
    // Ambil data dari Service
    final reviews = ReviewService.getReviewsForKost(kostId);
    final firstReview = reviews.isNotEmpty ? reviews.first : null;
    
    // Hitung rata-rata
    final avgRating = reviews.isNotEmpty 
        ? (reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length) 
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
                Text(' (${reviews.length})', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        // Preview Review Card
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
                    Text(firstReview.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Spacer(),
                    Text(firstReview.date, style: TextStyle(color: Colors.grey, fontSize: 11)),
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
          Text('Belum ada ulasan untuk kost ini.', style: TextStyle(color: Colors.grey)),

        SizedBox(height: 12),
        // Tombol Lihat Semua
        InkWell(
          onTap: () {
            // Navigasi ke ReviewScreen
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

class ProfileTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileTabViewModel>();
    final isPrivate = viewModel.isProfilePrivate;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Saya'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Info Header
          _buildUserInfo(context, viewModel.user),
          const SizedBox(height: 24),
          
          // Navigation Tiles
          _buildNavigationTile(
            context,
            title: 'Edit Data Pribadi',
            icon: Icons.person_outline,
            onTap: () {
              final vm = context.read<ProfileTabViewModel>();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(viewModel: vm)),
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
                MaterialPageRoute(builder: (_) => SettingsScreen(viewModel: vm)),
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
             style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 6),
           Text(
             user.email,
             style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
           ),
           const SizedBox(height: 8),
           // Gender & Tanggal Lahir
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
  
  Widget _buildNavigationTile(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : Colors.grey[700];
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
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
  const EditProfileScreen({Key? key, required this.viewModel}) : super(key: key);

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
                    Text('Jenis Kelamin', style: Theme.of(context).textTheme.bodyLarge),
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
                            activeColor: const Color.fromARGB(255, 239, 79, 254),
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
                    Text('Tanggal Lahir', style: Theme.of(context).textTheme.bodyLarge),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color.fromARGB(255, 32, 167, 240)!),
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