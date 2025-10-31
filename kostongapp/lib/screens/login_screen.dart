import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  String error = '';
  bool loading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      error = '';
      loading = true;
    });

    final res = await ApiService.login(emailC.text.trim(), passC.text);
    setState(() => loading = false);

    if (res['success'] == true) {
      // pass token and optionally user to home via route arguments
      final token = res['token'] as String?;
      Navigator.pushReplacementNamed(context, '/home', arguments: {'token': token});
    } else {
      setState(() {
        error = res['message'] ?? 'Login gagal';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final width = isWide ? 480.0 : double.infinity;

    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: width,
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_work, size: 64, color: Color(0xFF4A90E2)),
                    SizedBox(height: 12),
                    Text('Kostong', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2))),
                    SizedBox(height: 8),
                    Text('Login ke akun Anda', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(children: [
                        TextFormField(
                          controller: emailC,
                          decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                          validator: (v) => v == null || v.isEmpty ? 'Masukkan email' : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: passC,
                          obscureText: true,
                          decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                          validator: (v) => v == null || v.isEmpty ? 'Masukkan password' : null,
                        ),
                        SizedBox(height: 18),
                        loading ? CircularProgressIndicator() : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
                            child: Text('Login', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        if (error.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Text(error, style: TextStyle(color: Colors.red)),
                        ]
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
