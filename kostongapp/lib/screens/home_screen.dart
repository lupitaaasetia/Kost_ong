import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'dart:convert';

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
  bool _isInit = true;

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

    // Menggunakan fungsi-fungsi yang sudah ada di ApiService
    final futures = await Future.wait([
      ApiService.fetchKost(token),
      ApiService.fetchBooking(token),
      ApiService.fetchFavorit(token),
      ApiService.fetchRiwayat(token),
      ApiService.fetchReview(token!), // Pastikan token tidak null
      ApiService.fetchPembayaran(token),
      ApiService.fetchUserProfile(token!),
    ]);

    final keys = [
      'kost',
      'booking',
      'favorit',
      'riwayat',
      'review',
      'pembayaran',
      'user',
    ];
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
      });
      _fabController.forward();
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

  IconData _getIcon(String title) {
    switch (title.toLowerCase()) {
      case 'kost':
        return Icons.home_rounded;
      case 'booking':
        return Icons.event_note_rounded;
      case 'users':
        return Icons.people_rounded;
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

    return Container(
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
            title.toUpperCase(),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (userName != null)
              Text(
                'Selamat datang, $userName',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () => _loadAll()),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data...'),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: dataAll.length,
              itemBuilder: (context, index) {
                final key = dataAll.keys.elementAt(index);
                final content = dataAll[key];
                return _buildStatCard(key, content, index);
              },
            ),
      floatingActionButton: FadeTransition(
        opacity: _fabController,
        child: FloatingActionButton(
          onPressed: () => _loadAll(),
          child: Icon(Icons.refresh),
          tooltip: 'Muat Ulang Data',
        ),
      ),
    );
  }
}
