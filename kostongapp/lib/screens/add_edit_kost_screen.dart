import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class AddEditKostScreen extends StatefulWidget {
  final Map<String, dynamic>? kostData;
  final String token;

  const AddEditKostScreen({Key? key, this.kostData, required this.token})
    : super(key: key);

  @override
  State<AddEditKostScreen> createState() => _AddEditKostScreenState();
}

class _AddEditKostScreenState extends State<AddEditKostScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Controllers
  late TextEditingController _namaKostController;
  late TextEditingController _alamatController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _kontakController;

  String? _selectedJenisKost;
  String? _selectedStatus;
  List<String> _selectedFasilitas = [];

  final List<String> _jenisKostOptions = ['Putra', 'Putri', 'Campur'];
  final List<String> _statusOptions = ['Tersedia', 'Penuh', 'Renovasi'];
  final List<String> _fasilitasOptions = [
    'WiFi',
    'AC',
    'Kasur',
    'Lemari',
    'Meja Belajar',
    'Kamar Mandi Dalam',
    'Parkir Motor',
    'Parkir Mobil',
    'Dapur',
    'Laundry',
    'CCTV',
    'Keamanan 24 Jam',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // [PERBAIKAN KRITIS] Memuat data lama dengan aman
  void _initData() {
    // Helper untuk menangani data yang mungkin null, Map, atau String
    String getString(String key) {
      final value = widget.kostData?[key];
      if (value == null) return '';
      if (value is String) return value;

      // FIX: Jika alamat berbentuk Map (JSON Object), ambil string representatifnya
      if (value is Map) {
        return value['jalan'] ?? value['kota'] ?? value.toString();
      }
      return value.toString();
    }

    _namaKostController = TextEditingController(text: getString('nama_kost'));
    _alamatController = TextEditingController(
      text: getString('alamat'),
    ); // Sudah aman
    _deskripsiController = TextEditingController(text: getString('deskripsi'));

    // Handle harga (bisa int atau string dari API)
    _hargaController = TextEditingController(
      text:
          widget.kostData?['harga']?.toString() ??
          widget.kostData?['harga_per_bulan']?.toString() ??
          '',
    );

    _kontakController = TextEditingController(text: getString('kontak'));

    _selectedJenisKost = widget.kostData?['jenis_kost'];
    _selectedStatus = widget.kostData?['status'];

    // Handle Fasilitas (bisa String 'WiFi, AC' atau List ['WiFi', 'AC'])
    final rawFasilitas = widget.kostData?['fasilitas'];
    if (rawFasilitas != null) {
      if (rawFasilitas is List) {
        _selectedFasilitas = rawFasilitas.map((e) => e.toString()).toList();
      } else if (rawFasilitas is String) {
        _selectedFasilitas = rawFasilitas
            .split(',')
            .map((e) => e.trim())
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _namaKostController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final Map<String, dynamic> data = {
      'nama_kost': _namaKostController.text,
      // Alamat dikirim sebagai String ke backend, meskipun asalnya dari database bisa Map
      'alamat': _alamatController.text,
      'deskripsi': _deskripsiController.text,
      'harga': int.tryParse(_hargaController.text.replaceAll('.', '')) ?? 0,
      'kontak': _kontakController.text,
      'jenis_kost': _selectedJenisKost ?? 'Campur',
      'status': _selectedStatus ?? 'Tersedia',
      'fasilitas': _selectedFasilitas.join(','),
    };

    try {
      Map<String, dynamic> result;

      if (widget.kostData != null) {
        // Ambil ID dengan aman (Cek 'id' dan '_id' untuk Mongo)
        final id =
            widget.kostData!['id']?.toString() ??
            widget.kostData!['_id']?.toString();

        if (id == null) throw Exception("ID Kost tidak ditemukan");

        result = await ApiService.updateKost(widget.token, id, data);
      } else {
        result = await ApiService.createKost(widget.token, data);
      }

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.kostData != null
                    ? 'Kost diperbarui'
                    : 'Kost ditambahkan',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.kostData != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Kost' : 'Tambah Kost'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 1,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildTextField(
                    controller: _namaKostController,
                    label: 'Nama Kost',
                    icon: Icons.home_work,
                    validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _alamatController,
                    label: 'Alamat (Jalan, Kota)',
                    icon: Icons.location_on,
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _deskripsiController,
                    label: 'Deskripsi',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _hargaController,
                    label: 'Harga (Rp)',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: 16),
                  // Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Jenis',
                          _selectedJenisKost,
                          _jenisKostOptions,
                          (v) => setState(() => _selectedJenisKost = v),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          'Status',
                          _selectedStatus,
                          _statusOptions,
                          (v) => setState(() => _selectedStatus = v),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _kontakController,
                    label: 'No. WhatsApp',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Fasilitas",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _fasilitasOptions.map((f) {
                      final selected = _selectedFasilitas.contains(f);
                      return FilterChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val)
                              _selectedFasilitas.add(f);
                            else
                              _selectedFasilitas.remove(f);
                          });
                        },
                        checkmarkColor: Color(0xFF667eea),
                        selectedColor: Color(0xFF667eea).withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kost'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
