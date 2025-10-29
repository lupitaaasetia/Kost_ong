import 'package:flutter/material.dart';
import '../models/kost.dart';
import '../services/kost_service.dart';
import 'kost_detail_screen.dart';
import 'owner_add_kost_screen.dart';

class OwnerMyKostScreen extends StatefulWidget {
  final String ownerEmail;
  const OwnerMyKostScreen({super.key, required this.ownerEmail});
  @override
  State<OwnerMyKostScreen> createState() => _OwnerMyKostScreenState();
}

class _OwnerMyKostScreenState extends State<OwnerMyKostScreen> {
  final KostService _kostService = KostService();
  List<BaseKost> _myKostList = [];
  @override
  void initState() {
    super.initState();
    _loadMyKost();
  }

  void _loadMyKost() {
    _kostService.initializeData();
    setState(() {
      // filter by ownerEmail field on BaseKost
      _myKostList = _kostService.allKost
          .where((k) => k.ownerEmail == widget.ownerEmail)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kost Saya'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OwnerAddKostScreen(ownerEmail: widget.ownerEmail),
                ),
              ).then((_) => _loadMyKost());
            },
          ),
        ],
      ),
      body: _myKostList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myKostList.length,
              itemBuilder: (context, index) {
                return _buildKostCard(_myKostList[index]);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OwnerAddKostScreen(ownerEmail: widget.ownerEmail),
            ),
          ).then((_) => _loadMyKost());
        },
        backgroundColor: const Color(0xFF6B46C1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kost', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Kost',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai tambahkan kost Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OwnerAddKostScreen(ownerEmail: widget.ownerEmail),
                ),
              ).then((_) => _loadMyKost());
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kost Pertama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B46C1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKostCard(BaseKost kost) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KostDetailScreen(kost: kost),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (use first imageUrl if available)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: (kost.imageUrls.isNotEmpty)
                  ? Image.network(
                      kost.imageUrls.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.home_work,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.home_work,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          kost.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              kost.getKostType().toLowerCase().contains('laki')
                              ? Colors.blue[50]
                              : Colors.pink[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          kost.getKostType().toLowerCase().contains('laki')
                              ? 'Putra'
                              : 'Putri',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                kost.getKostType().toLowerCase().contains(
                                  'laki',
                                )
                                ? Colors.blue[700]
                                : Colors.pink[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          kost.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    kost.getFormattedPrice(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B46C1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Open add screen in edit mode
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OwnerAddKostScreen(
                                  ownerEmail: widget.ownerEmail,
                                  existingKost: kost,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadMyKost();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${kost.name} berhasil diperbarui',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6B46C1),
                            side: const BorderSide(color: Color(0xFF6B46C1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showDeleteDialog(kost);
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Hapus'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BaseKost kost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kost'),
        content: Text('Apakah Anda yakin ingin menghapus ${kost.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _kostService.deleteKost(kost.id);
              Navigator.pop(context);
              _loadMyKost();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${kost.name} berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }
}
