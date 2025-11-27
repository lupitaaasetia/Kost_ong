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
          'role': body['data']?['role'] ?? 'pencari', // Get role from response
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
  static Future<Map<String, dynamic>> register(
    String namaLengkap,
    String email,
    String password,
    String telepon,
    String role,
  ) async {
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
              'telepon': telepon,
              'role': role,
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
            'message': 'Server error ${res.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Generic GET checker
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
        // Handle both array response and object with data property
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

  // =========================
  // CRUD UNIVERSAL FUNCTIONS
  // =========================
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

  // =========================
  // Predefined fetches
  // =========================
  static Future<Map<String, dynamic>> fetchKost([String? token]) =>
      _getJson('/kost', token);
  static Future<Map<String, dynamic>> fetchBooking([String? token]) =>
      _getJson('/booking', token);
  static Future<Map<String, dynamic>> fetchUsers([String? token]) =>
      _getJson('/users', token);
  static Future<Map<String, dynamic>> fetchNotifikasi([String? token]) =>
      _getJson('/notifikasi', token);
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
}
