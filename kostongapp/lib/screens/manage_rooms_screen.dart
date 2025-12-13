import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ManageRoomsScreen extends StatefulWidget {
  final String kostId;
  final String kostName;
  final String token;

  const ManageRoomsScreen({
    Key? key,
    required this.kostId,
    required this.kostName,
    required this.token,
  }) : super(key: key);

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  bool _loading = true;
  List<dynamic> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);

    final result = await ApiService.fetchRoomsByKost(
      widget.token,
      widget.kostId,
    );

    if (result['success'] == true) {
      setState(() {
        _rooms = result['data'] ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _showSnackBar(result['message'] ?? 'Gagal memuat kamar', isError: true);
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

  Future<void> _deleteRoom(String roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Kamar'),
        content: Text('Yakin ingin menghapus kamar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteRoom(widget.token, roomId);

      if (result['success'] == true) {
        _showSnackBar('Kamar berhasil dihapus');
        _loadRooms();
      } else {
        _showSnackBar(
          result['message'] ?? 'Gagal menghapus kamar',
          isError: true,
        );
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? roomData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditRoomDialog(
        kostId: widget.kostId,
        token: widget.token,
        roomData: roomData,
        onSuccess: () => _loadRooms(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelola Kamar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.kostName,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  return _buildRoomCard(room);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Color(0xFF667eea),
        icon: Icon(Icons.add),
        label: Text('Tambah Kamar'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.meeting_room_outlined, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Belum ada kamar',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan kamar untuk kost ini',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final isAvailable = room['status']?.toString().toLowerCase() == 'tersedia';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.meeting_room,
                    color: isAvailable ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room['nomor_kamar']?.toString() ?? 'Kamar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rp ${room['harga'] ?? 0}/bulan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    room['status']?.toString() ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (room['deskripsi'] != null) ...[
              SizedBox(height: 12),
              Text(
                room['deskripsi'].toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddEditDialog(roomData: room),
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF667eea),
                      side: BorderSide(color: Color(0xFF667eea)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteRoom(room['id'].toString()),
                    icon: Icon(Icons.delete, size: 18),
                    label: Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditRoomDialog extends StatefulWidget {
  final String kostId;
  final String token;
  final Map<String, dynamic>? roomData;
  final VoidCallback onSuccess;

  const AddEditRoomDialog({
    Key? key,
    required this.kostId,
    required this.token,
    this.roomData,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<AddEditRoomDialog> createState() => _AddEditRoomDialogState();
}

class _AddEditRoomDialogState extends State<AddEditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _nomorKamarController;
  late TextEditingController _hargaController;
  late TextEditingController _deskripsiController;
  String? _selectedStatus;

  final List<String> _statusOptions = ['Tersedia', 'Terisi', 'Maintenance'];

  @override
  void initState() {
    super.initState();
    _nomorKamarController = TextEditingController(
      text: widget.roomData?['nomor_kamar'] ?? '',
    );
    _hargaController = TextEditingController(
      text: widget.roomData?['harga']?.toString() ?? '',
    );
    _deskripsiController = TextEditingController(
      text: widget.roomData?['deskripsi'] ?? '',
    );
    _selectedStatus = widget.roomData?['status'] ?? 'Tersedia';
  }

  @override
  void dispose() {
    _nomorKamarController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final data = {
      'kost_id': widget.kostId,
      'nomor_kamar': _nomorKamarController.text,
      'harga': _hargaController.text,
      'deskripsi': _deskripsiController.text,
      'status': _selectedStatus,
    };

    try {
      Map<String, dynamic> result;

      if (widget.roomData != null) {
        result = await ApiService.updateRoom(
          widget.token,
          widget.roomData!['id'].toString(),
          data,
        );
      } else {
        result = await ApiService.createRoom(widget.token, data);
      }

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[700]),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.roomData != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Kamar' : 'Tambah Kamar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nomorKamarController,
                decoration: InputDecoration(
                  labelText: 'Nomor Kamar',
                  prefixIcon: Icon(Icons.meeting_room),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _hargaController,
                decoration: InputDecoration(
                  labelText: 'Harga per Bulan',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
                validator: (v) => v == null ? 'Pilih status' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEdit ? 'Perbarui' : 'Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
