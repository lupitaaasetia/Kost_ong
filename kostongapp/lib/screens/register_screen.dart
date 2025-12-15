import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController namaC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController confirmPassC = TextEditingController();
  final TextEditingController teleponC = TextEditingController();
  final TextEditingController tglLahirC = TextEditingController();

  String error = '';
  bool loading = false;
  String selectedRole = 'pencari'; 
  String? selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? selectedDate;

  @override
  void dispose() {
    namaC.dispose();
    emailC.dispose();
    passC.dispose();
    confirmPassC.dispose();
    teleponC.dispose();
    tglLahirC.dispose();
    super.dispose();
  }

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

    if (passC.text != confirmPassC.text) {
      setState(() => error = 'Password tidak cocok');
      return;
    }

    setState(() {
      error = '';
      loading = true;
    });

    // ✅ PERBAIKAN: Memanggil API dengan argumen yang benar
    final res = await ApiService.register(
      namaC.text.trim(),
      emailC.text.trim(),
      passC.text,
      teleponC.text.trim(),
      selectedRole,
    );

    if (!mounted) return;

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
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
