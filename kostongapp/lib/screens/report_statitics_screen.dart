import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsStatisticsScreen extends StatefulWidget {
  final String token;

  const ReportsStatisticsScreen({Key? key, required this.token})
    : super(key: key);

  @override
  State<ReportsStatisticsScreen> createState() =>
      _ReportsStatisticsScreenState();
}

class _ReportsStatisticsScreenState extends State<ReportsStatisticsScreen> {
  bool _loading = true;
  Map<String, dynamic> _statistics = {};
  String _selectedPeriod = 'Bulan Ini';
  final List<String> _periods = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
  ];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loading = true);

    final result = await ApiService.fetchStatistics(
      widget.token,
      _selectedPeriod,
    );

    if (result['success'] == true) {
      setState(() {
        _statistics = result['data'] ?? {};
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _showSnackBar(
        result['message'] ?? 'Gagal memuat statistik',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Laporan & Statistik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    SizedBox(height: 24),
                    _buildRevenueCard(),
                    SizedBox(height: 16),
                    _buildStatisticsGrid(),
                    SizedBox(height: 24),
                    Text(
                      'Grafik Pendapatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildRevenueChart(),
                    SizedBox(height: 24),
                    Text(
                      'Pembayaran Terbaru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildRecentPayments(),
                    SizedBox(height: 24),
                    _buildOccupancyRate(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPeriod = period);
                  _loadStatistics();
                }
              },
              selectedColor: Color(0xFF667eea),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevenueCard() {
    final totalRevenue = _statistics['total_revenue'] ?? 0;
    final growthRate = _statistics['growth_rate'] ?? 0.0;
    final isPositive = growthRate >= 0;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pendapatan',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${growthRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Rp ${_formatCurrency(totalRevenue)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Periode: $_selectedPeriod',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final totalBookings = _statistics['total_bookings'] ?? 0;
    final confirmedBookings = _statistics['confirmed_bookings'] ?? 0;
    final activeRooms = _statistics['active_rooms'] ?? 0;
    final totalRooms = _statistics['total_rooms'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Booking',
                totalBookings.toString(),
                Icons.event_note,
                Color(0xFF4facfe),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Dikonfirmasi',
                confirmedBookings.toString(),
                Icons.check_circle,
                Color(0xFF43e97b),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Kamar Terisi',
                '$activeRooms/$totalRooms',
                Icons.meeting_room,
                Color(0xFFf093fb),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Tingkat Hunian',
                '${totalRooms > 0 ? ((activeRooms / totalRooms) * 100).toStringAsFixed(0) : 0}%',
                Icons.analytics,
                Color(0xFFfeca57),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildRevenueChart() {
    final chartData = _statistics['chart_data'] as List? ?? [];

    return Container(
      height: 200,
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
      child: chartData.isEmpty
          ? Center(
              child: Text(
                'Tidak ada data grafik',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : CustomPaint(
              painter: LineChartPainter(chartData),
              child: Container(),
            ),
    );
  }

  Widget _buildRecentPayments() {
    final payments = _statistics['recent_payments'] as List? ?? [];

    if (payments.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Belum ada pembayaran',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: payments.length > 5 ? 5 : payments.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final payment = payments[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: Icon(Icons.payment, color: Colors.green, size: 20),
            ),
            title: Text(
              payment['nama_penyewa']?.toString() ?? 'Penyewa',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              payment['tanggal']?.toString() ?? '-',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Text(
              'Rp ${_formatCurrency(payment['jumlah'] ?? 0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOccupancyRate() {
    final activeRooms = _statistics['active_rooms'] ?? 0;
    final totalRooms = _statistics['total_rooms'] ?? 1;
    final occupancyRate = (activeRooms / totalRooms) * 100;

    return Container(
      padding: EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tingkat Hunian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${occupancyRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: occupancyRate / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kamar Terisi: $activeRooms',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                'Total Kamar: $totalRooms',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = amount is String ? int.tryParse(amount) ?? 0 : amount as int;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<dynamic> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Color(0xFF667eea)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF667eea).withOpacity(0.3),
          Color(0xFF667eea).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxValue = data
        .map((e) => e['value'] as num)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final stepX = size.width / (data.length - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i]['value'] / maxValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
