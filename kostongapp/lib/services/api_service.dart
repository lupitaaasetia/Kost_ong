import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      try {
        if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
        if (Platform.isIOS) return 'http://127.0.0.1:3000/api';
      } catch (_) {}
      return 'http://localhost:3000/api';
    }
  }

  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> _headers([String? token]) {
    final h = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  // ==================== AUTH (EXISTING) ====================

  // LOGIN
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/users/login');
    try {
      final res = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? '',
          'token': body['token'],
          'data': body['data'],
          'role': body['data']?['role'] ?? 'pencari',
        };
      } else {
        try {
          final body = jsonDecode(res.body);
          return {'success': false, 'message': body['message'] ?? res.body};
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error ${res.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String email,
    required String password,
    required String noTelepon,
    required String role,
    required String jenisKelamin,
    required String tanggalLahir,
    required Map<String, String> alamat,
  }) async {
    final url = Uri.parse('$baseUrl/users/register');
    try {
      final res = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              'nama_lengkap': namaLengkap,
              'email': email,
              'password': password,
              'no_telepon': noTelepon,
              'role': role,
              'jenis_kelamin': jenisKelamin,
              'tanggal_lahir': tanggalLahir,
              'alamat': alamat,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Registrasi berhasil',
          'data': body['data'],
        };
      } else {
        try {
          final body = jsonDecode(res.body);
          return {'success': false, 'message': body['message'] ?? res.body};
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error ${res.statusCode}: ${res.body}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // LOGOUT
  static Future<Map<String, dynamic>> logout(String? token) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/users/logout'), headers: _headers(token))
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Logout berhasil'};
      }
      return {'success': false, 'message': 'Gagal logout'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== GENERIC GET HELPER ====================

  static Future<Map<String, dynamic>> _getJson(
    String endpoint, [
    String? token,
  ]) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final res = await http
          .get(url, headers: _headers(token))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          return {'success': true, 'data': body};
        } else if (body is Map && body.containsKey('data')) {
          return {'success': true, 'data': body['data']};
        } else {
          return {'success': true, 'data': body};
        }
      } else if (res.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized',
          'requiresLogin': true,
        };
      } else {
        try {
          final body = jsonDecode(res.body);
          return {'success': false, 'message': body['message'] ?? res.body};
        } catch (_) {
          return {'success': false, 'message': 'Server ${res.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== CRUD UNIVERSAL FUNCTIONS ====================

  static Future<Map<String, dynamic>> fetchCollection(
    String token,
    String type,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/$type'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          return {'success': true, 'data': body};
        } else if (body is Map && body.containsKey('data')) {
          return {'success': true, 'data': body['data']};
        } else {
          return {'success': true, 'data': body};
        }
      }

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createData(
    String token,
    String type,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/$type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateData(
    String token,
    String type,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/$type/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteData(
    String token,
    String type,
    String id,
  ) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/$type/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== PREDEFINED FETCHES (EXISTING) ====================

  static Future<Map<String, dynamic>> fetchKost([String? token]) =>
      _getJson('/kost', token);

  static Future<Map<String, dynamic>> fetchBooking([String? token]) =>
      _getJson('/booking', token);

  static Future<Map<String, dynamic>> fetchUsers([String? token]) =>
      _getJson('/users', token);

  static Future<Map<String, dynamic>> fetchFavorit([String? token]) =>
      _getJson('/favorit', token);

  static Future<Map<String, dynamic>> fetchRiwayat([String? token]) =>
      _getJson('/riwayat', token);

  static Future<Map<String, dynamic>> fetchReview([String? token]) =>
      _getJson('/review', token);

  static Future<Map<String, dynamic>> fetchPembayaran([String? token]) =>
      _getJson('/pembayaran', token);

  static Future<Map<String, dynamic>> fetchKontrak([String? token]) =>
      _getJson('/kontrak', token);

  // ==================== KOST SPECIFIC (NEW) ====================

  static Future<Map<String, dynamic>> fetchKostById(
    String? token,
    dynamic id,
  ) async {
    return _getJson('/kost/$id', token);
  }

  static Future<Map<String, dynamic>> createKost(
    String? token,
    Map<String, dynamic> data,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }
    return createData(token, 'kost', data);
  }

  static Future<Map<String, dynamic>> updateKost(
    String? token,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }
    return updateData(token, 'kost', id.toString(), data);
  }

  static Future<Map<String, dynamic>> deleteKost(
    String? token,
    dynamic id,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }
    return deleteData(token, 'kost', id.toString());
  }

  // ==================== BOOKING SPECIFIC (NEW) ====================

  static Future<Map<String, dynamic>> fetchBookingById(
    String? token,
    dynamic id,
  ) async {
    return _getJson('/booking/$id', token);
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
    String? token,
    dynamic id,
    String status,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }

    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/booking/$id/status'),
            headers: _headers(token),
            body: jsonEncode({'status': status}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Status berhasil diupdate',
          'data': body['data'],
        };
      } else {
        final body = jsonDecode(res.body);
        return {'success': false, 'message': body['message'] ?? res.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== NOTIFICATIONS (NEW) ====================

  static Future<Map<String, dynamic>> fetchNotifications(String? token) async {
    return _getJson('/notifications', token);
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(
    String? token,
    dynamic id,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }

    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/notifications/$id/read'),
            headers: _headers(token),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return {'success': true, 'message': 'Notifikasi ditandai sudah dibaca'};
      }
      return {'success': false, 'message': 'Gagal menandai notifikasi'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead(
    String? token,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }

    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/notifications/read-all'),
            headers: _headers(token),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': 'Semua notifikasi ditandai sudah dibaca',
        };
      }
      return {'success': false, 'message': 'Gagal menandai semua notifikasi'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== STATISTICS (NEW) ====================

  static Future<Map<String, dynamic>> fetchStatistics(
    String? token,
    String period,
  ) async {
    return _getJson('/statistics?period=$period', token);
  }

  // ==================== SETTINGS (NEW) ====================

  static Future<Map<String, dynamic>> fetchSettings(String? token) async {
    return _getJson('/settings', token);
  }

  static Future<Map<String, dynamic>> updateSettings(
    String? token,
    Map<String, dynamic> settings,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }

    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/settings'),
            headers: _headers(token),
            body: jsonEncode(settings),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Pengaturan berhasil disimpan',
          'data': body['data'],
        };
      } else {
        final body = jsonDecode(res.body);
        return {'success': false, 'message': body['message'] ?? res.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== PROFILE (NEW) ====================

  static Future<Map<String, dynamic>> fetchProfile(String? token) async {
    return _getJson('/profile', token);
  }

  static Future<Map<String, dynamic>> updateProfile(
    String? token,
    Map<String, dynamic> data,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }

    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/profile'),
            headers: _headers(token),
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Profil berhasil diupdate',
          'data': body['data'],
        };
      } else {
        final body = jsonDecode(res.body);
        return {'success': false, 'message': body['message'] ?? res.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> changePassword(
    String? token,
    String oldPassword,
    String newPassword,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/users/change-password'),
            headers: _headers(token),
            body: jsonEncode({
              'old_password': oldPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Password berhasil diubah',
        };
      } else {
        final body = jsonDecode(res.body);
        return {'success': false, 'message': body['message'] ?? res.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== DASHBOARD DATA (NEW) ====================

  static Future<Map<String, dynamic>> fetchDashboardData(String? token) async {
    return _getJson('/dashboard', token);
  }

  // ==================== UPLOAD IMAGE (NEW) ====================

  static Future<Map<String, dynamic>> uploadImage(
    String? token,
    String filePath,
    String fieldName,
  ) async {
    if (token == null) {
      return {'success': false, 'message': 'Token tidak tersedia'};
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Upload berhasil',
          'data': body['data'],
        };
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['message'] ?? response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== HELPER METHODS ====================

  static Future<bool> checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Placeholder for getting token from storage
  static Future<String?> getToken() async {
    // TODO: Implement using SharedPreferences to get the saved token.
    return null;
  }
}
