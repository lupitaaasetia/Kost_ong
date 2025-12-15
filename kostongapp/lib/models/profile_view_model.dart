import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String profileImageUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl = 'https://picsum.photos/seed/user/150',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? '',
      fullName: json['nama_lengkap'] ?? 'User',
      email: json['email'] ?? '',
      phoneNumber: json['no_telepon'] ?? '',
    );
  }
}

class ProfileTabViewModel extends ChangeNotifier {
  UserProfile _user;
  UserProfile get user => _user;

  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  String? selectedGender;
  DateTime? selectedDate;
  
  // ✅ PERBAIKAN: Tambahkan properti yang hilang
  bool isProfilePrivate = false;

  ProfileTabViewModel(Map<String, dynamic>? userData)
      : _user = UserProfile.fromJson(userData ?? {}) {
    fullNameController = TextEditingController(text: _user.fullName);
    phoneController = TextEditingController(text: _user.phoneNumber);
    emailController = TextEditingController(text: _user.email);
    selectedGender = userData?['jenis_kelamin'];
    if (userData?['tanggal_lahir'] != null) {
      selectedDate = DateTime.tryParse(userData!['tanggal_lahir']);
    }
  }

  void setGender(String? gender) {
    selectedGender = gender;
    notifyListeners();
  }

  void setDate(DateTime? date) {
    selectedDate = date;
    notifyListeners();
  }

  // ✅ PERBAIKAN: Tambahkan fungsi yang hilang
  void setPrivacy(bool isPrivate) {
    isProfilePrivate = isPrivate;
    notifyListeners();
  }

  Future<bool> changeEmail(String newEmail, String password) async {
    // Placeholder: Implementasi ganti email
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    // Placeholder: Implementasi ganti password
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final dataToUpdate = {
      'nama_lengkap': fullNameController.text,
      'no_telepon': phoneController.text,
      'jenis_kelamin': selectedGender,
      'tanggal_lahir': selectedDate?.toIso8601String(),
    };

    final result = await ApiService.updateUserProfile(token, dataToUpdate);

    if (result['success'] == true) {
      _user = UserProfile.fromJson(result['data']);
      await prefs.setString('user', jsonEncode(result['data']));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
