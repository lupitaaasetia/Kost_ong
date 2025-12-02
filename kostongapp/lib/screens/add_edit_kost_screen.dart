import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class AddEditKostScreen extends StatefulWidget {
  @override
  State<AddEditKostScreen> createState() => _AddEditKostScreenState();
}

class _AddEditKostScreenState extends State<AddEditKostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaKostController = TextEditingController();
  final _alamatController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _fasilitasController = TextEditingController();
  final _jumlahKamarController = TextEditingController();

  String? token;
  dynamic kostData;
  bool isEdit = false;
  bool loading = false;
  String selectedTipe = 'Putra';
  String selectedStatus = 'Tersedia';

  final List<String> tipeKost = ['Putra', 'Putri', 'Campur'];
  final List<String> statusKost = ['Tersedia', 'Penuh', 'Maintenance'];

  // Image handling
  List<File> selectedImages = [];
  List<String> existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  // Room management
  List<Map<String, dynamic>> kamarList = [];
  bool showRoomSection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      token = args['token'];
      kostData = args['kost'];

      if (kostData != null) {
        isEdit = true;
        _namaKostController.text = kostData['nama_kost']?.toString() ?? '';
        _alamatController.text = kostData['alamat']?.toString() ?? '';
        _hargaController.text = kostData['harga']?.toString() ?? '';
        _deskripsiController.text = kostData['deskripsi']?.toString() ?? '';
        _fasilitasController.text = kostData['fasilitas']?.toString() ?? '';
        _jumlahKamarController.text =
            kostData['jumlah_kamar']?.toString() ?? '';
        selectedTipe = kostData['tipe']?.toString() ?? 'Putra';
        selectedStatus = kostData['status']?.toString() ?? 'Tersedia';

        // Load existing images
        if (kostData['images'] != null && kostData['images'] is List) {
          existingImageUrls = List<String>.from(kostData['images']);
        }

        // Load existing rooms
        if (kostData['kamar'] != null && kostData['kamar'] is List) {
          kamarList = List<Map<String, dynamic>>.from(kostData['kamar']);
        }
      }
    }
  }

  @override
  void dispose() {
    _namaKostController.dispose();
    _alamatController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _fasilitasController.dispose();
    _jumlahKamarController.dispose();
    super.dispose();
  }

  // Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          selectedImages.addAll(images.map((img) => File(img.path)).toList());
        });
        _showSnackBar('${images.length} foto dipilih');
      }
    } catch (e) {
      _showSnackBar('Gagal memilih foto: $e', isError: true);
    }
  }

  // Remove selected image
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // Remove existing image
  void _removeExistingImage(int index) {
    setState(() {
      existingImageUrls.removeAt(index);
    });
  }

  // Add room dialog
  void _showAddRoomDialog() {
    final nomorKamarController = TextEditingController();
    final lantaiController = TextEditingController();
    final hargaKamarController = TextEditingController();
    String statusKamar = 'Tersedia';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Kamar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomorKamarController,
                decoration: InputDecoration(
                  labelText: 'Nomor Kamar',
                  hintText: 'Contoh: 101',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: lantaiController,
                decoration: InputDecoration(
                  labelText: 'Lantai',
                  hintText: 'Contoh: 1',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: hargaKamarController,
                decoration: InputDecoration(
                  labelText: 'Harga per Bulan',
                  hintText: 'Contoh: 1000000',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: statusKamar,
                decoration: InputDecoration(
                  labelText: 'Status Kamar',
                  border: OutlineInputBorder(),
                ),
                items: ['Tersedia', 'Terisi', 'Maintenance']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) {
                  statusKamar = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomorKamarController.text.isNotEmpty) {
                setState(() {
                  kamarList.add({
                    'nomor_kamar': nomorKamarController.text,
                    'lantai': lantaiController.text,
                    'harga': hargaKamarController.text,
                    'status': statusKamar,
                  });
                });
                Navigator.pop(context);
                _showSnackBar('Kamar berhasil ditambahkan');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF667eea)),
            child: Text('Tambah'),
          ),
        ],
      ),
    );
  }

  // Edit room dialog
  void _showEditRoomDialog(int index) {
    final room = kamarList[index];
    final nomorKamarController = TextEditingController(
      text: room['nomor_kamar'],
    );
    final lantaiController = TextEditingController(text: room['lantai']);
    final hargaKamarController = TextEditingController(text: room['harga']);
    String statusKamar = room['status'] ?? 'Tersedia';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Kamar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomorKamarController,
                decoration: InputDecoration(
                  labelText: 'Nomor Kamar',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: lantaiController,
                decoration: InputDecoration(
                  labelText: 'Lantai',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: hargaKamarController,
                decoration: InputDecoration(
                  labelText: 'Harga per Bulan',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: statusKamar,
                decoration: InputDecoration(
                  labelText: 'Status Kamar',
                  border: OutlineInputBorder(),
                ),
                items: ['Tersedia', 'Terisi', 'Maintenance']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) {
                  statusKamar = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                kamarList[index] = {
                  'nomor_kamar': nomorKamarController.text,
                  'lantai': lantaiController.text,
                  'harga': hargaKamarController.text,
                  'status': statusKamar,
                };
              });
              Navigator.pop(context);
              _showSnackBar('Kamar berhasil diupdate');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF667eea)),
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Remove room
  void _removeRoom(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Kamar'),
        content: Text(
          'Yakin ingin menghapus kamar ${kamarList[index]['nomor_kamar']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                kamarList.removeAt(index);
              });
              Navigator.pop(context);
              _showSnackBar('Kamar berhasil dihapus');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // Prepare multipart request
      var uri = Uri.parse(
        isEdit
            ? '${ApiService.baseUrl}/kost/${kostData['id']}'
            : '${ApiService.baseUrl}/kost',
      );

      var request = http.MultipartRequest(isEdit ? 'PUT' : 'POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['nama_kost'] = _namaKostController.text;
      request.fields['alamat'] = _alamatController.text;
      request.fields['harga'] = _hargaController.text;
      request.fields['deskripsi'] = _deskripsiController.text;
      request.fields['fasilitas'] = _fasilitasController.text;
      request.fields['jumlah_kamar'] = _jumlahKamarController.text;
      request.fields['tipe'] = selectedTipe;
      request.fields['status'] = selectedStatus;

      // Add rooms as JSON
      request.fields['kamar'] = jsonEncode(kamarList);

      // Add existing images (for edit)
      if (isEdit && existingImageUrls.isNotEmpty) {
        request.fields['existing_images'] = jsonEncode(existingImageUrls);
      }

      // Add new image files
      for (int i = 0; i < selectedImages.length; i++) {
        var file = selectedImages[i];
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();
        var multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: 'image_$i.jpg',
        );
        request.files.add(multipartFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(
          isEdit ? 'Kost berhasil diupdate' : 'Kost berhasil ditambahkan',
        );
        await Future.delayed(Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar(
          responseData['message'] ?? 'Terjadi kesalahan',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Gagal menyimpan data: $e', isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
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
          isEdit ? 'Edit Kost' : 'Tambah Kost',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: loading ? null : _submit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.home_work, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isEdit
                          ? 'Update informasi kost Anda'
                          : 'Tambahkan kost baru ke daftar properti',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Image Upload Section
            _buildSectionTitle('Foto Kost'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Existing images
                  if (existingImageUrls.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: existingImageUrls.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(entry.value),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(entry.key),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                  ],

                  // New selected images
                  if (selectedImages.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedImages.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(entry.value),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Add photo button
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('Tambah Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Form Fields
            _buildSectionTitle('Informasi Dasar'),
            SizedBox(height: 12),
            _buildTextField(
              controller: _namaKostController,
              label: 'Nama Kost',
              hint: 'Contoh: Kost Melati',
              icon: Icons.home,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Nama kost wajib diisi' : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _alamatController,
              label: 'Alamat Lengkap',
              hint: 'Jl. Contoh No. 123',
              icon: Icons.location_on,
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Alamat wajib diisi' : null,
            ),
            SizedBox(height: 24),

            _buildSectionTitle('Detail Kost'),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Tipe Kost',
                    value: selectedTipe,
                    items: tipeKost,
                    onChanged: (value) => setState(() => selectedTipe = value!),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _jumlahKamarController,
                    label: 'Jumlah Kamar',
                    hint: '10',
                    icon: Icons.meeting_room,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _hargaController,
                    label: 'Harga per Bulan',
                    hint: '1000000',
                    icon: Icons.payments,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Harga wajib diisi' : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Status',
                    value: selectedStatus,
                    items: statusKost,
                    onChanged: (value) =>
                        setState(() => selectedStatus = value!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            _buildSectionTitle('Deskripsi & Fasilitas'),
            SizedBox(height: 12),
            _buildTextField(
              controller: _deskripsiController,
              label: 'Deskripsi',
              hint: 'Deskripsikan kost Anda...',
              icon: Icons.description,
              maxLines: 4,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _fasilitasController,
              label: 'Fasilitas',
              hint: 'Contoh: WiFi, AC, Kamar Mandi Dalam',
              icon: Icons.check_circle,
              maxLines: 3,
            ),
            SizedBox(height: 24),

            // Room Management Section
            _buildSectionTitle('Manajemen Kamar'),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.meeting_room, color: Color(0xFF667eea)),
                    title: Text('Daftar Kamar (${kamarList.length})'),
                    trailing: IconButton(
                      icon: Icon(Icons.add_circle, color: Color(0xFF667eea)),
                      onPressed: _showAddRoomDialog,
                    ),
                  ),
                  if (kamarList.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: kamarList.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final room = kamarList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF667eea).withOpacity(0.1),
                            child: Text(
                              room['nomor_kamar'] ?? '-',
                              style: TextStyle(
                                color: Color(0xFF667eea),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text('Kamar ${room['nomor_kamar']}'),
                          subtitle: Text(
                            'Lantai ${room['lantai']} • Rp ${room['harga']}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  room['status'] ?? 'Tersedia',
                                  style: TextStyle(fontSize: 10),
                                ),
                                backgroundColor: (room['status'] == 'Tersedia')
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                padding: EdgeInsets.zero,
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditRoomDialog(index),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeRoom(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'Update Kost' : 'Tambah Kost',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
