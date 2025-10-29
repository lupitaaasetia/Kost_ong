// screens/owner_add_kost_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../utils/image_picker_helper.dart';
import '../models/kost.dart';
import '../services/kost_service.dart';
import 'package:aplikasi_kostqu/models/facility.dart';

class OwnerAddKostScreen extends StatefulWidget {
  final String ownerEmail;
  final BaseKost? existingKost;

  const OwnerAddKostScreen({
    super.key,
    required this.ownerEmail,
    this.existingKost,
  });

  @override
  State<OwnerAddKostScreen> createState() => _OwnerAddKostScreenState();
}

class _OwnerAddKostScreenState extends State<OwnerAddKostScreen> {
  final _formKey = GlobalKey<FormState>();
  final KostService _kostService = KostService();

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Selected values
  String _selectedKostType = 'Kost Perempuan';
  KostStatus _selectedStatus = KostStatus.available;
  List<String> _imageUrls = [];
  List<Facility> _selectedFacilities = [];

  // Type specific fields
  final _curfewTimeController = TextEditingController();
  bool _hasSecurityGuard = false;
  bool _hasWorkspace = false;
  bool _allowsSmoking = false;
  final _maleRoomsController = TextEditingController();
  final _femaleRoomsController = TextEditingController();
  bool _hasSeparateEntrance = false;

  // Image URL input controller
  final _imageUrlController = TextEditingController();

  final List<String> _kostTypes = [
    'Kost Perempuan',
    'Kost Laki-laki',
    'Kost Campur',
  ];

  // ...existing code...
  final List<Facility> _allFacilities = [
    Facility(
      id: 'wifi',
      type: FacilityType.general,
      name: 'WiFi',
      icon: Icons.wifi,
      color: Colors.blue,
    ),
    Facility(
      id: 'ac',
      type: FacilityType.general,
      name: 'AC',
      icon: Icons.ac_unit,
      color: Colors.cyan,
    ),
    Facility(
      id: 'bed',
      type: FacilityType.room,
      name: 'Kasur',
      icon: Icons.bed,
      color: Colors.brown,
    ),
    Facility(
      id: 'wardrobe',
      type: FacilityType.room,
      name: 'Lemari',
      icon: Icons.checkroom,
      color: Colors.orange,
    ),
    Facility(
      id: 'ensuite',
      type: FacilityType.room,
      name: 'Kamar Mandi Dalam',
      icon: Icons.bathroom,
      color: Colors.teal,
    ),
    Facility(
      id: 'kitchen',
      type: FacilityType.general,
      name: 'Dapur',
      icon: Icons.kitchen,
      color: Colors.red,
    ),
    Facility(
      id: 'motor_parking',
      type: FacilityType.parking,
      name: 'Parkir Motor',
      icon: Icons.two_wheeler,
      color: Colors.purple,
    ),
    Facility(
      id: 'car_parking',
      type: FacilityType.parking,
      name: 'Parkir Mobil',
      icon: Icons.directions_car,
      color: Colors.indigo,
    ),
    Facility(
      id: 'laundry',
      type: FacilityType.service,
      name: 'Laundry',
      icon: Icons.local_laundry_service,
      color: Colors.pink,
    ),
    Facility(
      id: 'tv',
      type: FacilityType.room,
      name: 'TV',
      icon: Icons.tv,
      color: Colors.deepOrange,
    ),
  ];
  // ...existing code...

  @override
  void initState() {
    super.initState();
    _kostService.initializeData();
    // If editing an existing kost, prefill fields
    if (widget.existingKost != null) {
      final k = widget.existingKost!;
      _nameController.text = k.name;
      _addressController.text = k.address;
      _descriptionController.text = k.description;
      _priceController.text = k.pricePerMonth.toString();
      _phoneController.text = k.phoneNumber;
      _latitudeController.text = k.latitude.toString();
      _longitudeController.text = k.longitude.toString();
      _imageUrls = List.from(k.imageUrls);
      _selectedFacilities = List.from(k.facilities);
      _selectedStatus = k.status;
      // try to detect type
      _selectedKostType = k.getKostType();
      if (k is FemaleKost) {
        _hasSecurityGuard = k.hasSecurityGuard;
        _curfewTimeController.text = k.curfewTime;
      } else if (k is MaleKost) {
        _hasWorkspace = k.hasWorkspace;
        _allowsSmoking = k.allowsSmoking;
      } else if (k is MixedKost) {
        _maleRoomsController.text = k.maleRooms.toString();
        _femaleRoomsController.text = k.femaleRooms.toString();
        _hasSeparateEntrance = k.hasSeparateEntrance;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _curfewTimeController.dispose();
    _maleRoomsController.dispose();
    _femaleRoomsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tambah Kost Baru'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Informasi Dasar', Icons.info),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('Tipe Kost', Icons.home),
            _buildKostTypeSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('Lokasi', Icons.location_on),
            _buildLocationSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('Foto Kost', Icons.photo_library),
            _buildImageSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('Fasilitas', Icons.check_circle),
            _buildFacilitiesSection(),
            const SizedBox(height: 24),

            if (_selectedKostType == 'Kost Perempuan')
              _buildFemaleKostSection(),
            if (_selectedKostType == 'Kost Laki-laki') _buildMaleKostSection(),
            if (_selectedKostType == 'Kost Campur') _buildMixedKostSection(),

            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B46C1), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B46C1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kost *',
                hintText: 'Contoh: Kost Melati Indah',
                prefixIcon: Icon(Icons.home_work),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama kost harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap *',
                hintText: 'Jl. Contoh No. 123, Kota',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alamat harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi *',
                hintText: 'Jelaskan tentang kost Anda',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga per Bulan (Rp) *',
                hintText: '1000000',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harga harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon *',
                hintText: '081234567890',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor telepon harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<KostStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status Kost',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              items: KostStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKostTypeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Tipe Kost *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._kostTypes.map((type) {
              return RadioListTile<String>(
                title: Text(type),
                value: type,
                groupValue: _selectedKostType,
                activeColor: const Color(0xFF6B46C1),
                onChanged: (value) {
                  setState(() {
                    _selectedKostType = value!;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude *',
                hintText: '-7.250445',
                prefixIcon: Icon(Icons.pin_drop),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Latitude harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude *',
                hintText: '112.768845',
                prefixIcon: Icon(Icons.pin_drop),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Longitude harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Gunakan Google Maps untuk mendapatkan koordinat lokasi yang akurat',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL Gambar',
                      hintText: 'https://example.com/image.jpg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_imageUrlController.text.isNotEmpty) {
                          setState(() {
                            _imageUrls.add(_imageUrlController.text);
                            _imageUrlController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 40),
                      ),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickImageFromDevice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(48, 40),
                      ),
                      child: const Icon(Icons.photo_library),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_imageUrls.isNotEmpty) ...[
              const Text(
                'Foto yang Ditambahkan:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // If network/image loading fails, try rendering as memory (base64) fallback
                                if (_imageUrls[index].startsWith('data:')) {
                                  try {
                                    final comma = _imageUrls[index].indexOf(
                                      ',',
                                    );
                                    final b64 = _imageUrls[index].substring(
                                      comma + 1,
                                    );
                                    final bytes = base64Decode(b64);
                                    return Image.memory(
                                      bytes,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    );
                                  } catch (_) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    );
                                  }
                                }
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageUrls.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minimal 1 foto, maksimal 5 foto untuk hasil terbaik',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Fasilitas yang Tersedia',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allFacilities.map((facility) {
                final isSelected = _selectedFacilities.contains(facility);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        facility.icon,
                        size: 16,
                        color: isSelected ? Colors.white : facility.color,
                      ),
                      const SizedBox(width: 4),
                      Text(facility.name),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: facility.color,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFacilities.add(facility);
                      } else {
                        _selectedFacilities.remove(facility);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFemaleKostSection() {
    return Column(
      children: [
        _buildSectionTitle('Informasi Kost Perempuan', Icons.woman),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _curfewTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Malam',
                    hintText: 'Contoh: 22:00 WIB',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Ada Security Guard'),
                  subtitle: const Text('Keamanan 24 jam'),
                  value: _hasSecurityGuard,
                  activeColor: const Color(0xFF6B46C1),
                  onChanged: (value) {
                    setState(() {
                      _hasSecurityGuard = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMaleKostSection() {
    return Column(
      children: [
        _buildSectionTitle('Informasi Kost Laki-laki', Icons.man),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tersedia Workspace'),
                  subtitle: const Text('Ruang kerja/belajar'),
                  value: _hasWorkspace,
                  activeColor: const Color(0xFF6B46C1),
                  onChanged: (value) {
                    setState(() {
                      _hasWorkspace = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Boleh Merokok'),
                  subtitle: const Text('Area merokok tersedia'),
                  value: _allowsSmoking,
                  activeColor: const Color(0xFF6B46C1),
                  onChanged: (value) {
                    setState(() {
                      _allowsSmoking = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMixedKostSection() {
    return Column(
      children: [
        _buildSectionTitle('Informasi Kost Campur', Icons.people),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _maleRoomsController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Kamar Laki-laki',
                    hintText: '5',
                    prefixIcon: Icon(Icons.meeting_room),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _femaleRoomsController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Kamar Perempuan',
                    hintText: '5',
                    prefixIcon: Icon(Icons.meeting_room),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Pintu Masuk Terpisah'),
                  subtitle: const Text('Pintu masuk pria dan wanita berbeda'),
                  value: _hasSeparateEntrance,
                  activeColor: const Color(0xFF6B46C1),
                  onChanged: (value) {
                    setState(() {
                      _hasSeparateEntrance = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _submitForm,
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'Simpan Kost',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B46C1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Minimal tambahkan 1 foto kost!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedFacilities.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih minimal 1 fasilitas!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        BaseKost newKost;
        final id =
            widget.existingKost?.id ??
            'kost_${DateTime.now().millisecondsSinceEpoch}';
        final commonData = {
          'name': _nameController.text,
          'address': _addressController.text,
          'description': _descriptionController.text,
          'price': int.parse(_priceController.text),
          'phoneNumber': _phoneController.text,
          'latitude': double.parse(_latitudeController.text),
          'longitude': double.parse(_longitudeController.text),
          'imageUrls': _imageUrls,
          'facilities': _selectedFacilities,
          'status': _selectedStatus,
          'ownerEmail': widget.ownerEmail,
        };

        if (_selectedKostType == 'Kost Perempuan') {
          newKost = FemaleKost(
            id: id,
            name: commonData['name'] as String,
            address: commonData['address'] as String,
            description: commonData['description'] as String,
            pricePerMonth: commonData['price'] as int,
            imageUrls: commonData['imageUrls'] as List<String>,
            facilities: commonData['facilities'] as List<Facility>,
            phoneNumber: commonData['phoneNumber'] as String,
            latitude: commonData['latitude'] as double,
            longitude: commonData['longitude'] as double,
            rating: 0.0,
            status: commonData['status'] as KostStatus,
            curfewTime: _curfewTimeController.text.isNotEmpty
                ? _curfewTimeController.text
                : '22:00 WIB',
            hasSecurityGuard: _hasSecurityGuard,
          );
        } else if (_selectedKostType == 'Kost Laki-laki') {
          newKost = MaleKost(
            id: id,
            name: commonData['name'] as String,
            address: commonData['address'] as String,
            description: commonData['description'] as String,
            pricePerMonth: commonData['price'] as int,
            imageUrls: commonData['imageUrls'] as List<String>,
            facilities: commonData['facilities'] as List<Facility>,
            phoneNumber: commonData['phoneNumber'] as String,
            latitude: commonData['latitude'] as double,
            longitude: commonData['longitude'] as double,
            rating: 0.0,
            status: commonData['status'] as KostStatus,
            hasWorkspace: _hasWorkspace,
            allowsSmoking: _allowsSmoking,
          );
        } else {
          newKost = MixedKost(
            id: id,
            name: commonData['name'] as String,
            address: commonData['address'] as String,
            description: commonData['description'] as String,
            pricePerMonth: commonData['price'] as int,
            imageUrls: commonData['imageUrls'] as List<String>,
            facilities: commonData['facilities'] as List<Facility>,
            phoneNumber: commonData['phoneNumber'] as String,
            latitude: commonData['latitude'] as double,
            longitude: commonData['longitude'] as double,
            rating: 0.0,
            status: commonData['status'] as KostStatus,
            maleRooms: int.tryParse(_maleRoomsController.text) ?? 0,
            femaleRooms: int.tryParse(_femaleRoomsController.text) ?? 0,
            hasSeparateEntrance: _hasSeparateEntrance,
          );
        }

        if (widget.existingKost != null) {
          _kostService.updateKost(newKost);
        } else {
          _kostService.addKost(newKost);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kost berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromDevice() async {
    try {
      final bytes = await ImagePickerHelper.pickImage();
      if (bytes == null) return;

      // Convert to data URI so Image.network / Image.memory can render on web easily
      final mime = 'image/jpeg';
      final base64Data = base64Encode(bytes);
      final dataUri = 'data:$mime;base64,$base64Data';

      setState(() {
        _imageUrls.add(dataUri);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }
}
