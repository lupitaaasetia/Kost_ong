import 'package:flutter/material.dart';
import '../models/profile_view_model.dart';

class HistoryScreen extends StatelessWidget {
  final ProfileTabViewModel viewModel;

  const HistoryScreen({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transactions = viewModel.transactions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi'),
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Belum ada transaksi', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final trx = transactions[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!)
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      child: Icon(Icons.receipt_long),
                    ),
                    title: Text(trx.service, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${trx.date.day}/${trx.date.month}/${trx.date.year} - ID: ${trx.id}'),
                    trailing: _buildStatusBadge(trx.status),
                    onTap: () {
                      // Optional: Show transaction detail dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Detail untuk transaksi ${trx.id}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text = status;
    switch (status) {
      case 'Berhasil': color = Colors.green; break;
      case 'Pending': color = Colors.orange; break;
      case 'Gagal': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}