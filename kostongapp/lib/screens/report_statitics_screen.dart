import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsStatisticsScreen extends StatefulWidget {
  final String token;

  const ReportsStatisticsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ReportsStatisticsScreen> createState() => _ReportsStatisticsScreenState();
}

class _ReportsStatisticsScreenState extends State<ReportsStatisticsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (mounted) setState(() => _loading = true);

    // ✅ PERBAIKAN: Memanggil dengan argumen yang benar
    final result = await ApiService.fetchStatistics(widget.token);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _stats = result['data'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memuat statistik'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan & Statistik'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 1,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(child: Text('Tidak ada data statistik.'))
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      _buildSummaryGrid(),
                      SizedBox(height: 24),
                      _buildMonthlyIncomeChart(),
                      SizedBox(height: 24),
                      _buildBookingStatusChart(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Pendapatan',
          'Rp ${(_stats!['total_pendapatan'] ?? 0)}',
          Icons.monetization_on,
          Colors.green,
        ),
        _buildStatCard(
          'Total Booking',
          '${_stats!['total_booking'] ?? 0}',
          Icons.event_note,
          Colors.blue,
        ),
        _buildStatCard(
          'Okupansi',
          '${_stats!['okupansi'] ?? 0}%',
          Icons.hotel,
          Colors.orange,
        ),
        _buildStatCard(
          'Rating Rata-rata',
          '${_stats!['rating_rata_rata'] ?? 0}',
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 28, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyIncomeChart() {
    final List<double> monthlyIncome = List<double>.from(
      (_stats!['pendapatan_bulanan'] as List<dynamic>?)?.map((e) => (e as num).toDouble()) ?? []
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pendapatan Bulanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: monthlyIncome.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.blue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('Bln ${value.toInt() + 1}'),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatusChart() {
    final Map<String, int> bookingStatus = Map<String, int>.from(
      (_stats!['booking_status'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {}
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: bookingStatus.entries.map((entry) {
                    Color color;
                    switch (entry.key) {
                      case 'pending': color = Colors.orange; break;
                      case 'active': color = Colors.green; break;
                      case 'cancelled': color = Colors.red; break;
                      default: color = Colors.grey;
                    }
                    return PieChartSectionData(
                      color: color,
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      radius: 80,
                      titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bookingStatus.entries.map((entry) {
                Color color;
                switch (entry.key) {
                  case 'pending': color = Colors.orange; break;
                  case 'active': color = Colors.green; break;
                  case 'cancelled': color = Colors.red; break;
                  default: color = Colors.grey;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Container(width: 16, height: 16, color: color),
                      SizedBox(width: 4),
                      Text(entry.key.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
