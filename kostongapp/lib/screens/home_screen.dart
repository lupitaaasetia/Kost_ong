import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;
  String? token;
  Map<String, dynamic> dataAll = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    token = args != null ? args['token'] as String? : null;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);

    // fetch data (tanpa kontrak dan riwayat)
    final futures = await Future.wait([
      ApiService.fetchKost(token),
      ApiService.fetchBooking(token),
      ApiService.fetchUsers(token),
      ApiService.fetchNotifikasi(token),
      ApiService.fetchFavorit(token),
      ApiService.fetchReview(token),
      ApiService.fetchPembayaran(token),
    ]);

    // assign ke map
    final keys = ['kost', 'booking', 'users', 'notifikasi', 'favorit', 'review', 'pembayaran'];
    final tmp = <String, dynamic>{};
    for (int i = 0; i < keys.length; i++) {
      final r = futures[i] as Map<String, dynamic>;
      if (r['success'] == true) {
        tmp[keys[i]] = r['data'];
      } else {
        tmp[keys[i]] = {'error': r['message'] ?? 'gagal'};
      }
    }

    setState(() {
      dataAll = tmp;
      loading = false;
    });
  }

  Widget _buildCard(String title, dynamic content) {
    // jika error
    if (content is Map && content.containsKey('error')) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: ListTile(
            title: Text(title),
            subtitle: Text('Error: ${content['error']}'),
            trailing: IconButton(icon: Icon(Icons.refresh), onPressed: _loadAll),
          ),
        ),
      );
    }

    // jika list
    if (content is List) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: ExpansionTile(
            title: Text('$title (${content.length})'),
            children: content.take(50).map<Widget>((item) {
              final pretty = _prettyPrint(item);
              return ListTile(
                title: Text(pretty.keys.isNotEmpty ? pretty.keys.first : 'Item'),
                subtitle: Text(pretty.values.isNotEmpty ? pretty.values.first.toString() : item.toString()),
                isThreeLine: true,
                onTap: () => _showJsonDialog(item),
              );
            }).toList(),
          ),
        ),
      );
    }

    // fallback tampilkan apa adanya
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: ListTile(
          title: Text(title),
          subtitle: Text(content.toString()),
        ),
      ),
    );
  }

  Map<String, dynamic> _prettyPrint(dynamic item) {
    if (item is Map<String, dynamic>) {
      final prefer = ['nama_lengkap', 'name', 'title', 'email', 'nama'];
      for (var k in prefer) {
        if (item.containsKey(k)) return {k: item[k]};
      }
      if (item.isNotEmpty) return {item.keys.first: item.values.first};
    }
    return {};
  }

  void _showJsonDialog(dynamic item) {
    final formatted = item != null ? item.toString() : 'null';
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Detail'),
        content: SingleChildScrollView(child: Text(formatted)),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final columns = isWide ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kostong — Dashboard'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadAll),
          IconButton(icon: Icon(Icons.logout), onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          }),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildCard('Kost', dataAll['kost']),
                  _buildCard('Booking', dataAll['booking']),
                  _buildCard('Users', dataAll['users']),
                  _buildCard('Notifikasi', dataAll['notifikasi']),
                  _buildCard('Favorit', dataAll['favorit']),
                  _buildCard('Review', dataAll['review']),
                  _buildCard('Pembayaran', dataAll['pembayaran']),
                ],
              ),
            ),
    );
  }
}
