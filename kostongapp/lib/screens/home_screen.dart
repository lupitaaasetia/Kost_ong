import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'dart:convert';
import '../screens/crud_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool loading = true;
  String? token;
  Map<String, dynamic> dataAll = {};
  String? userName;
  late AnimationController _animController;

  late AnimationController _fabController;
  Timer? _autoRefreshTimer;

  bool _isInit = true; // <-- PERBAIKAN 2: Flag untuk didChangeDependencies

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

  // Auto refresh every 5 minutes
  _autoRefreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
    if (mounted) _loadAll(showLoading: false);
  });
}

  @override
  void dispose() {
    _animController.dispose();
    _fabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // <-- PERBAIKAN 2: Hanya jalankan ini satu kali saat inisialisasi
    if (_isInit) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      token = args != null ? args['token'] as String? : null;

      // Extract user name if available
      if (args != null && args['data'] != null) {
        final userData = args['data'] as Map<String, dynamic>?;
        userName =
            userData?['nama_lengkap'] ?? userData?['name'] ?? userData?['email'];
      }

      _loadAll();
      _isInit = false; // Set flag agar tidak dijalankan lagi
    }
  }

  Future<void> _loadAll({bool showLoading = true}) async {
    if (showLoading) {
      if (mounted) setState(() => loading = true);
      _animController.forward(from: 0);
    }

    // Pastikan token ada sebelum fetch
    if (token == null) {
      if (mounted) {
        setState(() => loading = false);
        _showSnackBar('Token tidak ditemukan, silakan login ulang.', isError: true);
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/');
        });
      }
      return;
    }

    final futures = await Future.wait([
      ApiService.fetchKost(token),
      ApiService.fetchBooking(token),
      ApiService.fetchUsers(token),
      ApiService.fetchNotifikasi(token),
      ApiService.fetchFavorit(token),
      ApiService.fetchRiwayat(token),
      ApiService.fetchReview(token),
      ApiService.fetchPembayaran(token),
      ApiService.fetchKontrak(token),
    ]);

    final keys = [
      'kost',
      'booking',
      'users',
      'notifikasi',
      'favorit',
      'riwayat',
      'review',
      'pembayaran',
      'kontrak',
    ];
    final tmp = <String, dynamic>{};

    for (int i = 0; i < keys.length; i++) {
      final r = futures[i] as Map<String, dynamic>;
      if (r['success'] == true) {
        tmp[keys[i]] = r['data'];
      } else {
        tmp[keys[i]] = {'error': r['message'] ?? 'gagal'};

        // If unauthorized, redirect to login
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
      _fabController.forward();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Cek mounted sebelum panggil ScaffoldMessenger
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

  IconData _getIcon(String title) {
    switch (title.toLowerCase()) {
      case 'kost':
        return Icons.home_rounded;
      case 'booking':
        return Icons.event_note_rounded;
      case 'users':
        return Icons.people_rounded;
      case 'notifikasi':
        return Icons.notifications_rounded;
      case 'favorit':
        return Icons.favorite_rounded;
      case 'riwayat':
        return Icons.history_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'pembayaran':
        return Icons.payment_rounded;
      case 'kontrak':
        return Icons.description_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  Color _getColor(int index) {
    final colors = [
      Color(0xFF667eea),
      Color(0xFFf093fb),
      Color(0xFF4facfe),
      Color(0xFFfa709a),
      Color(0xFFfeca57),
      Color(0xFF48dbfb),
      Color(0xFFff6348),
      Color(0xFF00d2d3),
      Color(0xFF5f27cd),
    ];
    return colors[index % colors.length];
  }

  Widget _buildStatCard(String title, dynamic content, int index) {
    final color = _getColor(index);
    int count = 0;
    bool hasError = false;

    if (content is Map && content.containsKey('error')) {
      hasError = true;
    } else if (content is List) {
      count = content.length;
    }

    return InkWell(
      onTap: () => _showDetailSheet(title, content, index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(title), color: Colors.white, size: 28),
                ),
                if (hasError)
                  Icon(Icons.error_outline, color: Colors.white70, size: 24)
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
            Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              hasError ? 'Error memuat data' : '$count items',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(String title, dynamic content, int index) {
    final color = _getColor(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIcon(title),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(Icons.settings, size: 18),
      label: Text('Kelola ${title}'),
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => CrudScreen(token: token!, type: title.toLowerCase()),
          ),
        );
      },
    ),
    SizedBox(width: 12),
  ],
),

                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (content is List)
                                Text(
                                  '${content.length} items',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildDetailContent(content, scrollController, color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(
    dynamic content,
    ScrollController controller,
    Color color,
  ) {
    if (content is Map && content.containsKey('error')) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                content['error'],
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _loadAll();
              },
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (content is List) {
      if (content.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'Tidak ada data',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        controller: controller,
        padding: EdgeInsets.all(16),
        itemCount: content.length,
        separatorBuilder: (c, i) => Divider(height: 1),
        itemBuilder: (c, i) {
          final item = content[i];
          final pretty = _prettyPrint(item);
          // <-- PERBAIKAN 4: Cek tipe data subtitle
          final subtitleValue = pretty.values.isNotEmpty ? pretty.values.first : null;

          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              title: Text(
                pretty.keys.isNotEmpty ? pretty.keys.first : 'Item ${i + 1}',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              // <-- PERBAIKAN 4: Hanya tampilkan subtitle jika datanya simpel (bukan Map/List)
              subtitle: (subtitleValue != null &&
                      subtitleValue is! Map &&
                      subtitleValue is! List)
                  ? Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        subtitleValue.toString(),
                        style: TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : null,
              trailing: Icon(Icons.chevron_right, color: color),
              onTap: () => _showJsonDialog(item),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(content.toString()),
        ),
      ),
    );
  }

  Map<String, dynamic> _prettyPrint(dynamic item) {
    if (item is Map<String, dynamic>) {
      final prefer = [
        'nama_lengkap',
        'name',
        'title',
        'email',
        'nama',
        'alamat',
      ];
      for (var k in prefer) {
        if (item.containsKey(k)) return {k: item[k]};
      }
      if (item.isNotEmpty) return {item.keys.first: item.values.first};
    }
    return {};
  }

  void _showJsonDialog(dynamic item) {
    // <-- PERBAIKAN 5: Gunakan JsonEncoder untuk format yang rapi
    final formatted = item != null
        ? JsonEncoder.withIndent('  ').convert(item)
        : 'null';
        
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF667eea)),
                  SizedBox(width: 8),
                  Text(
                    'Detail Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(c),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      formatted, // <-- PERBAIKAN 5: Tampilkan JSON yang sudah diformat
                      style: TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 1200;
    final isMedium = size.width > 800;
    final isSmall = size.width > 600;

    // <-- PERBAIKAN 3: Hitung jumlah notifikasi secara dinamis
    int notifCount = 0;
    if (!loading && dataAll['notifikasi'] is List) {
      notifCount = (dataAll['notifikasi'] as List).length;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.home_work_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kostong',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                if (userName != null)
                  Text(
                    'Halo, $userName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              _showSnackBar('Fitur pencarian segera hadir');
            },
            tooltip: 'Cari',
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_rounded, color: Colors.white),
                // <-- PERBAIKAN 3: Tampilkan badge hanya jika ada notifikasi
                if (notifCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Center(
                        child: Text(
                          '$notifCount', // <-- PERBAIKAN 3: Gunakan jumlah dinamis
                          style: TextStyle(color: Colors.white, fontSize: 8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (notifCount > 0) {
                _showSnackBar('$notifCount notifikasi baru');
              } else {
                _showSnackBar('Tidak ada notifikasi baru');
              }
            },
            tooltip: 'Notifikasi',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                _showSnackBar('Fitur profil segera hadir');
              } else if (value == 'settings') {
                _showSnackBar('Fitur pengaturan segera hadir');
              } else if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Profil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Pengaturan'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF667eea),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Memuat data...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[50]!, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: FadeTransition(
                opacity: _animController,
                child: RefreshIndicator(
                  onRefresh: () => _loadAll(),
                  color: Color(0xFF667eea),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWide
                                ? 4
                                : (isMedium ? 3 : (isSmall ? 2 : 1)),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final keys = [
                              'kost',
                              'booking',
                              'users',
                              'notifikasi',
                              'favorit',
                              'riwayat',
                              'review',
                              'pembayaran',
                              'kontrak',
                            ];
                            final titles = [
                              'Kost',
                              'Booking',
                              'Users',
                              'Notifikasi',
                              'Favorit',
                              'Riwayat',
                              'Review',
                              'Pembayaran',
                              'Kontrak',
                            ];
                            return _buildStatCard(
                              titles[index],
                              dataAll[keys[index]],
                              index,
                            );
                          }, childCount: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: () => _loadAll(),
          backgroundColor: Color(0xFF667eea),
          icon: Icon(Icons.refresh_rounded),
          label: Text('Refresh'),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF667eea)),
            SizedBox(width: 8),
            Text('Konfirmasi Logout'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pushReplacementNamed(context, '/');
              _showSnackBar('Logout berhasil');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}