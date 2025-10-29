// services/auth_service.dart
import '../models/user.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  User? _currentUser;
  final Map<String, String> _userPasswords = {}; // email: password
  final Map<String, User> _registeredUsers = {}; // email: User

  // Initialize with demo users
  void _initializeDemoUsers() {
    if (_registeredUsers.isEmpty) {
      final demoUsers = [
        User(
          id: '1',
          name: 'Test User',
          email: 'test@gmail.com',
          phoneNumber: '081234567890',
          role: UserRole.customer,
          createdAt: DateTime.now(),
          isVerified: true,
        ),
        User(
          id: '2',
          name: 'Owner Demo',
          email: 'owner@gmail.com',
          phoneNumber: '081234567891',
          role: UserRole.owner,
          createdAt: DateTime.now(),
          isVerified: true,
        ),
        User(
          id: '3',
          name: 'Admin KostQu',
          email: 'admin@gmail.com',
          phoneNumber: '081234567892',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          isVerified: true,
        ),
      ];

      for (var user in demoUsers) {
        _registeredUsers[user.email] = user;
        _userPasswords[user.email] = 'password';
      }
    }
  }

  AuthService._internal() {
    _initializeDemoUsers();
  }

  // Get current user
  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  // Register new user
  Future<RegisterResult> register(RegisterRequest request) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    // Validate email
    if (_registeredUsers.containsKey(request.email)) {
      return RegisterResult(success: false, message: 'Email sudah terdaftar');
    }

    // Create new user
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name,
      email: request.email,
      phoneNumber: request.phoneNumber,
      role: request.role,
      createdAt: DateTime.now(),
      isVerified: false,
    );

    _registeredUsers[user.email] = user;
    _userPasswords[user.email] = request.password;

    return RegisterResult(
      success: true,
      message: 'Registrasi berhasil! Silakan login.',
      user: user,
    );
  }

  // Login
  Future<LoginResult> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    final user = _registeredUsers[email];
    final storedPassword = _userPasswords[email];

    if (user == null || storedPassword != password) {
      return LoginResult(success: false, message: 'Email atau password salah');
    }

    _currentUser = user.copyWith(lastLoginAt: DateTime.now());

    _registeredUsers[email] = _currentUser!;

    return LoginResult(
      success: true,
      message: 'Login berhasil',
      user: _currentUser,
    );
  }

  // Logout
  void logout() {
    _currentUser = null;
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser?.id != updatedUser.id) {
      return false;
    }

    _currentUser = updatedUser;
    _registeredUsers[updatedUser.email] = updatedUser;
    return true;
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser == null) return false;

    final storedPassword = _userPasswords[_currentUser!.email];
    if (storedPassword != oldPassword) {
      return false;
    }

    _userPasswords[_currentUser!.email] = newPassword;
    return true;
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));

    if (!_registeredUsers.containsKey(email)) {
      return false;
    }

    // In real app, send email with reset link
    return true;
  }

  // Upgrade to owner
  Future<bool> upgradeToOwner(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser?.id != userId) return false;

    _currentUser = _currentUser!.copyWith(role: UserRole.owner);
    _registeredUsers[_currentUser!.email] = _currentUser!;
    return true;
  }

  // Get user by id
  User? getUserById(String userId) {
    return _registeredUsers.values.firstWhere(
      (user) => user.id == userId,
      orElse: () => User(
        id: userId,
        name: 'Unknown User',
        email: 'unknown@email.com',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      ),
    );
  }

  // Get all registered users (for demo)
  Map<String, String> getValidCredentials() {
    return Map.from(_userPasswords);
  }

  // Get all users
  List<User> getAllUsers() {
    return _registeredUsers.values.toList();
  }
}

// Result classes
class LoginResult {
  final bool success;
  final String message;
  final User? user;

  LoginResult({required this.success, required this.message, this.user});
}

class RegisterResult {
  final bool success;
  final String message;
  final User? user;

  RegisterResult({required this.success, required this.message, this.user});
}
