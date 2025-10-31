// minimal API service for web + other platforms
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiService {
  // auto base url (web: localhost)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      // for non-web use emulator default for convenience
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
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/users/login');
    try {
      final res = await http
          .post(url, headers: _headers(), body: jsonEncode({'email': email, 'password': password}))
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? '',
          'token': body['token'],
          'data': body['data'],
        };
      } else {
        // try decode error message
        try {
          final body = jsonDecode(res.body);
          return {'success': false, 'message': body['message'] ?? res.body};
        } catch (_) {
          return {'success': false, 'message': 'Server error ${res.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Generic GET checker
  static Future<Map<String, dynamic>> _getJson(String endpoint, [String? token]) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final res = await http.get(url, headers: _headers(token)).timeout(_timeout);
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
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

  // Endpoints to fetch lists (adjust names to work with your backend)
  static Future<Map<String, dynamic>> fetchKost([String? token]) => _getJson('/kost', token);
  static Future<Map<String, dynamic>> fetchBooking([String? token]) => _getJson('/booking', token);
  static Future<Map<String, dynamic>> fetchUsers([String? token]) => _getJson('/users', token);
  static Future<Map<String, dynamic>> fetchNotifikasi([String? token]) => _getJson('/notifikasi', token);
  static Future<Map<String, dynamic>> fetchFavorit([String? token]) => _getJson('/favorit', token);
  static Future<Map<String, dynamic>> fetchRiwayat([String? token]) => _getJson('/riwayat', token);
  static Future<Map<String, dynamic>> fetchReview([String? token]) => _getJson('/review', token);
  static Future<Map<String, dynamic>> fetchPembayaran([String? token]) => _getJson('/pembayaran', token);
  static Future<Map<String, dynamic>> fetchKontrak([String? token]) => _getJson('/kontrak', token);
}
