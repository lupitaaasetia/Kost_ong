import 'package:flutter/material.dart';

// Using the same UserProfile model, but it will be managed here.
class UserProfile {
  String fullName;
  String? gender;
  DateTime? dateOfBirth;
  String phoneNumber;
  String email;
  String profileImageUrl;

  UserProfile({
    required this.fullName,
    this.gender,
    this.dateOfBirth,
    required this.phoneNumber,
    required this.email,
    this.profileImageUrl = 'https://i.pravatar.cc/150?img=12',
  });
}

class Transaction {
  final String id;
  final DateTime date;
  final String service;
  final String status;
  final double amount;

  Transaction({
    required this.id,
    required this.date,
    required this.service,
    required this.status,
    required this.amount,
  });
}

class ProfileTabViewModel extends ChangeNotifier {
  // --- State ---
  late UserProfile _user;
  bool _isProfilePrivate = false;
  final List<Transaction> _transactions;

  // --- Controllers for Edit Profile form ---
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  String? _selectedGender;
  DateTime? _selectedDate;

  // --- Getters ---
  UserProfile get user => _user;
  bool get isProfilePrivate => _isProfilePrivate;
  List<Transaction> get transactions => _transactions;
  String? get selectedGender => _selectedGender;
  DateTime? get selectedDate => _selectedDate;

  ProfileTabViewModel(Map<String, dynamic>? userData)
      : _transactions = [ // Dummy transaction data
          Transaction(id: 'INV12345', date: DateTime(2025, 11, 20), service: 'Sewa Kost Bulan November', status: 'Berhasil', amount: 1500000),
          Transaction(id: 'INV12344', date: DateTime(2025, 10, 20), service: 'Sewa Kost Bulan Oktober', status: 'Berhasil', amount: 1500000),
          Transaction(id: 'INV12343', date: DateTime(2025, 9, 20), service: 'Booking Fee Kost Melati', status: 'Gagal', amount: 500000),
          Transaction(id: 'INV12342', date: DateTime(2025, 9, 19), service: 'Deposit Kunci', status: 'Pending', amount: 250000),
        ]
        {
          _user = UserProfile(
            fullName: userData?['nama_lengkap'] ?? 'User',
            email: userData?['email'] ?? 'user@example.com',
            gender: userData?['jenis_kelamin'],
            dateOfBirth: userData?['tanggal_lahir'] != null ? DateTime.tryParse(userData?['tanggal_lahir']) : null,
            phoneNumber: userData?['telepon'] ?? '',
          );

          // Initialize controllers
          fullNameController = TextEditingController(text: _user.fullName);
          phoneController = TextEditingController(text: _user.phoneNumber);
          emailController = TextEditingController(text: _user.email);
          _selectedGender = _user.gender;
          _selectedDate = _user.dateOfBirth;
        }

  // --- Actions ---
  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void saveProfile() {
    // Update the main user model
    _user.fullName = fullNameController.text;
    _user.phoneNumber = phoneController.text;
    _user.email = emailController.text;
    _user.gender = _selectedGender;
    _user.dateOfBirth = _selectedDate;
    
    print('Profile Saved: ${_user.fullName}, Phone: ${_user.phoneNumber}, Gender: ${_user.gender}');
    notifyListeners();
  }

  void setPrivacy(bool isPrivate) {
    _isProfilePrivate = isPrivate;
    notifyListeners();
  }

  Future<bool> changeEmail(String newEmail, String password) async {
    // Simulate API call
    print('Attempting to change email to $newEmail with password: $password');
    // In a real app, you would verify the password and update the email via an API.
    // For now, we'll just simulate success and update the local state.
    _user.email = newEmail;
    emailController.text = newEmail;
    notifyListeners();
    return true;
  }

  Future<bool> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    // Simulate API call
    print('Attempting to change password. Old: $oldPassword, New: $newPassword');
    if (newPassword != confirmPassword) {
      print('New passwords do not match.');
      return false;
    }
    // In a real app, you would send old and new passwords to your API.
    // For now, we'll just simulate success.
    return true;
  }

  void addNewTransaction(dynamic kost) {
    // Create a new transaction from the kost data
    final newTransaction = Transaction(
      // Generate a semi-random ID for demo purposes
      id: 'INV${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: DateTime.now(),
      service: 'Booking ${kost['nama_kost'] ?? 'Kost'}',
      // All new bookings start as 'Pending'
      status: 'Pending',
      amount: (kost['harga'] ?? 0).toDouble(),
    );

    // Add to the beginning of the list
    _transactions.insert(0, newTransaction);
    
    // Notify listeners to rebuild widgets that use this data
    notifyListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
