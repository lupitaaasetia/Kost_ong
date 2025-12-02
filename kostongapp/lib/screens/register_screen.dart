import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers Data Diri
  final TextEditingController namaC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController confirmPassC = TextEditingController();
  final TextEditingController teleponC = TextEditingController();
  final TextEditingController tglLahirC = TextEditingController();

  // Controllers Alamat (Wajib sesuai Database)
  final TextEditingController jalanC = TextEditingController();
  final TextEditingController kelurahanC = TextEditingController();
  final TextEditingController kecamatanC = TextEditingController();
  final TextEditingController kotaC = TextEditingController();
  final TextEditingController provinsiC = TextEditingController();
  final TextEditingController kodePosC = TextEditingController();

  String error = '';
  bool loading = false;
  String selectedRole = 'pencari'; 
  String? selectedGender; // Untuk dropdown jenis kelamin
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? selectedDate;

  // Fungsi Helper Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        tglLahirC.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedGender == null) {
      setState(() => error = 'Pilih jenis kelamin');
      return;
    }

    if (passC.text != confirmPassC.text) {
      setState(() => error = 'Password tidak cocok');
      return;
    }

    setState(() {
      error = '';
      loading = true;
    });

    // Memanggil API dengan data lengkap sesuai schema Database
    final res = await ApiService.register(
      namaLengkap: namaC.text.trim(),
      email: emailC.text.trim(),
      password: passC.text,
      noTelepon: teleponC.text.trim(),
      role: selectedRole,
      jenisKelamin: selectedGender!,
      tanggalLahir: selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      alamat: {
        'jalan': jalanC.text.trim(),
        'kelurahan': kelurahanC.text.trim(),
        'kecamatan': kecamatanC.text.trim(),
        'kota': kotaC.text.trim(),
        'provinsi': provinsiC.text.trim(),
        'kode_pos': kodePosC.text.trim(),
      },
    );

    setState(() => loading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Registrasi berhasil! Silakan login.')),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      });
    } else {
      setState(() {
        error = res['message'] ?? 'Registrasi gagal';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final width = isWide ? 520.0 : double.infinity;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: width,
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Icon(Icons.home_work, size: 48, color: Color(0xFF667eea)),
                      SizedBox(height: 16),
                      Text(
                        'Daftar Akun',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Role Switcher
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildRoleButton('pencari', 'Pencari', Icons.person_search)),
                            Expanded(child: _buildRoleButton('pemilik', 'Pemilik', Icons.business)),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Form Input
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Data Diri"),
                            _buildTextField(controller: namaC, label: 'Nama Lengkap', icon: Icons.person),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: emailC, 
                              label: 'Email', 
                              icon: Icons.email, 
                              keyboardType: TextInputType.emailAddress
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: teleponC, 
                              label: 'No. Telepon', 
                              icon: Icons.phone, 
                              keyboardType: TextInputType.phone
                            ),
                            SizedBox(height: 12),
                            
                            // Dropdown Gender
                            DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: _inputDecoration('Jenis Kelamin', Icons.wc),
                              items: ['Laki-laki', 'Perempuan'].map((String val) {
                                return DropdownMenuItem(value: val, child: Text(val));
                              }).toList(),
                              onChanged: (v) => setState(() => selectedGender = v),
                              validator: (v) => v == null ? 'Pilih jenis kelamin' : null,
                            ),
                            SizedBox(height: 12),

                            // Date Picker
                            TextFormField(
                              controller: tglLahirC,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              decoration: _inputDecoration('Tanggal Lahir', Icons.calendar_today),
                              validator: (v) => v!.isEmpty ? 'Isi tanggal lahir' : null,
                            ),
                            
                            SizedBox(height: 24),
                            _sectionTitle("Alamat Lengkap"),
                            
                            // Form Alamat
                            _buildTextField(controller: jalanC, label: 'Jalan (mis: Jl. Mawar No.1)', icon: Icons.add_road),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildTextField(controller: kelurahanC, label: 'Kelurahan', icon: Icons.map)),
                                SizedBox(width: 12),
                                Expanded(child: _buildTextField(controller: kecamatanC, label: 'Kecamatan', icon: Icons.map_outlined)),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildTextField(controller: kotaC, label: 'Kota/Kab', icon: Icons.location_city)),
                                SizedBox(width: 12),
                                Expanded(child: _buildTextField(controller: provinsiC, label: 'Provinsi', icon: Icons.public)),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildTextField(controller: kodePosC, label: 'Kode Pos', icon: Icons.numbers, keyboardType: TextInputType.number),

                            SizedBox(height: 24),
                            _sectionTitle("Keamanan"),
                            _buildTextField(
                              controller: passC,
                              label: 'Password',
                              icon: Icons.lock,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: confirmPassC,
                              label: 'Konfirmasi Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              validator: (v) => v != passC.text ? 'Password tidak sama' : null,
                            ),

                            SizedBox(height: 32),
                            // Tombol Daftar
                            loading
                                ? Center(child: CircularProgressIndicator())
                                : SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF667eea),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                            
                            // Error
                            if (error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(error, style: TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
                              ),

                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey[700])),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(context, '/'),
                                  child: Text('Login', style: TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
    );
  }

  Widget _buildRoleButton(String role, String label, IconData icon) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF667eea) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
            SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF667eea)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF667eea), width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
      isDense: true,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator ?? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      decoration: _inputDecoration(label, icon, suffixIcon: suffixIcon),
    );
  }
}