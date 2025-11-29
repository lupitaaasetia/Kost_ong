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

    final futures = await Future.wait([
      ApiService.fetchKost(token),
      ApiService.fetchBooking(token),
      ApiService.fetchUsers(token),
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
    final key = _getTitleKey(title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildSheetHeader(title, content, color, key),
              Expanded(
                child: _buildDetailContent(
                  content,
                  scrollController,
                  color,
                  key,
                  title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(
    String title,
    dynamic content,
    Color color,
    String key,
  ) {
    return Container(
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
                child: Icon(_getIcon(title), color: Colors.white, size: 24),
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
              // Add button
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditDialog(null, key, title, color);
                },
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTitleKey(String title) {
    return title.toLowerCase();
  }

  Widget _buildDetailContent(
    dynamic content,
    ScrollController controller,
    Color color,
    String key,
    String title,
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
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditDialog(null, key, title, color);
                },
                icon: Icon(Icons.add),
                label: Text('Tambah Data'),
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

      return ListView.separated(
        controller: controller,
        padding: EdgeInsets.all(16),
        itemCount: content.length,
        separatorBuilder: (c, i) => SizedBox(height: 8),
        itemBuilder: (c, i) {
          final item = content[i];
          return _buildItemCard(item, i, color, key, title);
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

  Widget _buildItemCard(
    dynamic item,
    int index,
    Color color,
    String key,
    String title,
  ) {
    final displayData = _getDisplayData(item);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: () => _showItemDetail(item, color, key, title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayData['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (displayData['subtitle'] != null) ...[
                          SizedBox(height: 4),
                          Text(
                            displayData['subtitle']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) {
                      if (value == 'view') {
                        _showItemDetail(item, color, key, title);
                      } else if (value == 'edit') {
                        // Tutup bottom sheet dulu
                        Navigator.pop(context);
                        _showAddEditDialog(item, key, title, color);
                      } else if (value == 'delete') {
                        _showDeleteDialog(item, key, title, color);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 18,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text('Lihat Detail'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (displayData['badges'].isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: displayData['badges'].map<Widget>((badge) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getDisplayData(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return {'title': item.toString(), 'subtitle': null, 'badges': <String>[]};
    }

    String title = 'Item';
    String? subtitle;
    List<String> badges = [];

    // Priority fields for title
    final titleFields = [
      'nama_lengkap',
      'name',
      'nama',
      'title',
      'judul',
      'nama_kost',
      'nama_pemesan',
    ];
    for (var field in titleFields) {
      if (item.containsKey(field) && item[field] != null) {
        title = item[field].toString();
        break;
      }
    }

    // Fields for subtitle
    final subtitleFields = [
      'email',
      'alamat',
      'deskripsi',
      'keterangan',
      'status',
    ];
    for (var field in subtitleFields) {
      if (item.containsKey(field) && item[field] != null) {
        subtitle = item[field].toString();
        break;
      }
    }

    // Create badges from important fields
    if (item.containsKey('harga') && item['harga'] != null) {
      badges.add('Rp ${item['harga']}');
    }
    if (item.containsKey('status') && item['status'] != null) {
      badges.add(item['status'].toString());
    }
    if (item.containsKey('tanggal') && item['tanggal'] != null) {
      badges.add(item['tanggal'].toString());
    }
    if (item.containsKey('tanggal_booking') &&
        item['tanggal_booking'] != null) {
      badges.add(item['tanggal_booking'].toString());
    }
    if (item.containsKey('durasi') && item['durasi'] != null) {
      badges.add('${item['durasi']} hari');
    }
    if (item.containsKey('rating') && item['rating'] != null) {
      badges.add('⭐ ${item['rating']}');
    }

    return {'title': title, 'subtitle': subtitle, 'badges': badges};
  }

  void _showItemDetail(dynamic item, Color color, String key, String title) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info_outline, color: color),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail $title',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      Navigator.pop(c); // Tutup dialog detail
                      Navigator.pop(context); // Tutup bottom sheet
                      _showAddEditDialog(item, key, title, color);
                    },
                  ),
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
                  child: _buildDetailView(item, color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFieldName(String key) {
    if (key.isEmpty) return '';
    // Mengganti '_' dengan ' ' dan membuat huruf besar di setiap kata
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Widget _buildDetailView(dynamic item, Color color) {
    if (item is! Map<String, dynamic>) {
      return Text(item.toString());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatFieldName(entry.key),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  entry.value?.toString() ?? '-',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<String> _getFieldsForType(String key, dynamic item) {
    // Mode Edit: Ambil keys dari item yang ada
    if (item != null && item is Map<String, dynamic>) {
      return item.keys.toList();
    }

    // Mode Tambah: Coba ambil keys dari item pertama di list
    final listData = dataAll[key];
    if (listData is List && listData.isNotEmpty) {
      if (listData.first is Map<String, dynamic>) {
        // Hapus 'id' atau 'created_at' agar tidak diisi manual
        return (listData.first as Map<String, dynamic>).keys
            .where(
              (k) =>
                  k != 'id' &&
                  k != 'created_at' &&
                  k != 'updated_at' &&
                  k != 'id_user',
            )
            .toList();
      }
    }

    // Mode Tambah (Fallback): Jika list kosong, pakai hardcode
    switch (key) {
      case 'kost':
        return ['nama_kost', 'alamat', 'harga', 'tipe_kamar', 'fasilitas'];
      case 'users':
        return ['nama_lengkap', 'email', 'password', 'role'];
      case 'booking':
        return ['id_kost', 'tanggal_booking', 'durasi', 'status'];
      default:
        return ['nama', 'deskripsi'];
    }
  }

  List<String> _getStatusOptions(String key) {
    switch (key) {
      case 'booking':
        return ['Pending', 'Confirmed', 'Cancelled', 'Completed'];
      case 'pembayaran':
        return ['Pending', 'Paid', 'Failed'];
      case 'kost':
        return ['Tersedia', 'Penuh', 'Perbaikan'];
      default:
        return ['Active', 'Inactive'];
    }
  }

  void _showAddEditDialog(dynamic item, String key, String title, Color color) {
    final isEdit = item != null;
    final controllers = <String, TextEditingController>{};
    final dropdownValues = <String, String?>{};

    // Get fields based on type
    final fields = _getFieldsForType(key, item);

    for (var field in fields) {
      if (field == 'status' || field == 'tipe_kamar' || field == 'fasilitas') {
        // Dropdown fields
        dropdownValues[field] = item != null && item is Map
            ? item[field]?.toString()
            : null;
      } else {
        // Text fields
        controllers[field] = TextEditingController(
          text: item != null && item is Map
              ? item[field]?.toString() ?? ''
              : '',
        );
      }
    }

    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            padding: EdgeInsets.all(24),
            constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit : Icons.add,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${isEdit ? 'Edit' : 'Tambah'} $title',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
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
                    child: Column(
                      children: fields.map((field) {
                        // Handle dropdown fields
                        if (field == 'status') {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: DropdownButtonFormField<String>(
                              value: dropdownValues[field],
                              decoration: InputDecoration(
                                labelText: _formatFieldName(field),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: _getStatusOptions(key).map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  dropdownValues[field] = value;
                                });
                              },
                            ),
                          );
                        } else if (field == 'fasilitas') {
                          // TODO: Ini seharusnya multi-select, tapi disederhanakan jadi dropdown
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: DropdownButtonFormField<String>(
                              value: dropdownValues[field],
                              decoration: InputDecoration(
                                labelText: _formatFieldName(field),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items:
                                  [
                                    'WiFi',
                                    'Parkir',
                                    'Dapur',
                                    'Laundry',
                                    'TV',
                                    'Lemari',
                                  ].map((fas) {
                                    return DropdownMenuItem(
                                      value: fas,
                                      child: Text(fas),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  dropdownValues[field] = value;
                                });
                              },
                            ),
                          );
                        } else {
                          // Text field
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: controllers[field],
                              decoration: InputDecoration(
                                labelText: _formatFieldName(field),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType:
                                  (field == 'harga' ||
                                      field == 'durasi' ||
                                      field.contains('id'))
                                  ? TextInputType.number
                                  : (field == 'email')
                                  ? TextInputType.emailAddress
                                  : (field == 'alamat' || field == 'deskripsi')
                                  ? TextInputType.multiline
                                  : TextInputType.text,
                              maxLines:
                                  (field == 'alamat' || field == 'deskripsi')
                                  ? 3
                                  : 1,
                            ),
                          );
                        }
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Kumpulkan data
                      final newData = <String, dynamic>{};
                      controllers.forEach((key, controller) {
                        newData[key] = controller.text;
                      });
                      dropdownValues.forEach((key, value) {
                        newData[key] = value;
                      });

                      // Panggil save handler
                      _handleSave(key, newData, item);
                      Navigator.pop(c); // Tutup dialog
                    },
                    child: Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(dynamic item, String key, String title, Color color) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text(
          'Anda yakin ingin menghapus item "${_getDisplayData(item)['title']}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c); // Tutup dialog konfirmasi
              Navigator.pop(context); // Tutup bottom sheet
              _handleDelete(item, key);
            },
            child: Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(
    String key,
    Map<String, dynamic> data,
    dynamic oldItem,
  ) async {
    final isEdit = oldItem != null;
    if (token == null) return;

    // Remove non-editable fields
    data.remove('id');
    data.remove('_id');
    data.remove('created_at');
    data.remove('updated_at');

    try {
      final result = isEdit
          ? await ApiService.updateData(token!, key, oldItem['_id'], data)
          : await ApiService.createData(token!, key, data);

      if (result['success'] == true) {
        _showSnackBar(
          'Data ${isEdit ? 'berhasil diperbarui' : 'berhasil ditambahkan'}',
        );
        _loadAll(showLoading: false);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal menyimpan data', isError: true);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  Future<void> _handleDelete(dynamic item, String key) async {
    if (token == null || item == null || item['_id'] == null) return;
    final id = item['_id'];

    try {
      final result = await ApiService.deleteData(token!, key, id);
      if (result['success'] == true) {
        _showSnackBar('Item berhasil dihapus');
        _loadAll(showLoading: false);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal menghapus item', isError: true);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _logout() {
    setState(() {
      token = null;
    });
    Navigator.pushReplacementNamed(context, '/');
  }

  // --- METODE BUILD UTAMA ---

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
                childAspectRatio: 1, // Membuat kartu menjadi persegi
              ),
              itemCount: dataAll.length,
              itemBuilder: (context, index) {
                final key = dataAll.keys.elementAt(index);
                final content = dataAll[key];
                return _buildStatCard(
                  _formatFieldName(key), // Menggunakan nama yang diformat
                  content,
                  index,
                );
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
