import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/booking_model.dart'; // Pastikan import ini ada

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

  static Future<Map<String, dynamic>> _postJson(
    String endpoint,
    String token,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final res = await http
          .post(url, headers: _headers(token), body: jsonEncode(data))
          .timeout(_timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Success',
          'data': body['data'],
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

  static Future<Map<String, dynamic>> _putJson(
    String endpoint,
    String token,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final res = await http
          .put(url, headers: _headers(token), body: jsonEncode(data))
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Updated successfully',
          'data': body['data'],
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

  static Future<Map<String, dynamic>> _deleteJson(
    String endpoint,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final res = await http
          .delete(url, headers: _headers(token))
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': body['success'] ?? true,
          'message': body['message'] ?? 'Deleted successfully',
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
    return _getJson('/$type', token);
  }

  static Future<Map<String, dynamic>> createData(
    String token,
    String type,
    Map<String, dynamic> data,
  ) async {
    return _postJson('/$type', token, data);
  }

  static Future<Map<String, dynamic>> updateData(
    String token,
    String type,
    String id,
    Map<String, dynamic> data,
  ) async {
    return _putJson('/$type/$id', token, data);
  }

  static Future<Map<String, dynamic>> deleteData(
    String token,
    String type,
    String id,
  ) async {
    return _deleteJson('/$type/$id', token);
  }

  // =====================
  // KOST CRUD
  // =====================

  static Future<Map<String, dynamic>> fetchKostById(
    String token,
    String kostId,
  ) => _getJson('/kost/$kostId', token);

  static Future<Map<String, dynamic>> createKost(
    String token,
    Map<String, dynamic> data,
  ) => _postJson('/kost', token, data);

  static Future<Map<String, dynamic>> updateKost(
    String token,
    String kostId,
    Map<String, dynamic> data,
  ) => _putJson('/kost/$kostId', token, data);

  static Future<Map<String, dynamic>> deleteKost(String token, String kostId) =>
      _deleteJson('/kost/$kostId', token);

  // =====================
  // ROOM (KAMAR) CRUD
  // =====================

  static Future<Map<String, dynamic>> fetchRoomsByKost(
    String token,
    String kostId,
  ) => _getJson('/kost/$kostId/rooms', token);

  static Future<Map<String, dynamic>> createRoom(
    String token,
    Map<String, dynamic> data,
  ) => _postJson('/rooms', token, data);

  static Future<Map<String, dynamic>> updateRoom(
    String token,
    String roomId,
    Map<String, dynamic> data,
  ) => _putJson('/rooms/$roomId', token, data);

  static Future<Map<String, dynamic>> deleteRoom(String token, String roomId) =>
      _deleteJson('/rooms/$roomId', token);

  // =====================
  // BOOKING CRUD
  // =====================

  static Future<Map<String, dynamic>> fetchBookingById(
    String token,
    String bookingId,
  ) => _getJson('/booking/$bookingId', token);

  static Future<Map<String, dynamic>> createBooking(
    String token,
    Map<String, dynamic> data,
  ) => _postJson('/booking', token, data);

  static Future<Map<String, dynamic>> updateBookingStatus(
    String token,
    String bookingId,
    String status,
  ) => _putJson('/booking/$bookingId/status', token, {'status': status});

  static Future<Map<String, dynamic>> deleteBooking(
    String token,
    String bookingId,
  ) => _deleteJson('/booking/$bookingId', token);

  // Fungsi untuk mengambil list booking user (Dipakai di History Screen)
  static Future<List<BookingModel>> fetchUserBookings(String token, String userId) async {
    final response = await _getJson('/booking/user/$userId', token);
    
    if (response['success'] == false) {
      throw Exception(response['message']);
    }

    // _getJson sudah menghandle parsing body, jadi kita tinggal cek 'data'
    final data = response['data'];

    if (data is List) {
       return data.map((item) => BookingModel.fromJson(item)).toList();
    }
    
    return [];
  }

  // =====================
  // REVIEW CRUD
  // =====================

  static Future<Map<String, dynamic>> fetchReviewByKost(
    String token,
    String kostId,
  ) => _getJson('/review/kost/$kostId', token);

  static Future<Map<String, dynamic>> createReview(
    String token,
    Map<String, dynamic> data,
  ) => _postJson('/review', token, data);

  static Future<Map<String, dynamic>> replyToReview(
    String token,
    String reviewId,
    String reply,
  ) => _putJson('/review/$reviewId/reply', token, {'reply': reply});

  static Future<Map<String, dynamic>> deleteReview(
    String token,
    String reviewId,
  ) => _deleteJson('/review/$reviewId', token);

  // =====================
  // STATISTICS & REPORTS
  // =====================

  static Future<Map<String, dynamic>> fetchStatistics(
    String token,
    String period,
  ) async {
    // Mock data untuk testing - ganti dengan endpoint asli
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'success': true,
      'data': {
        'total_revenue': 15000000,
        'growth_rate': 12.5,
        'total_bookings': 25,
        'confirmed_bookings': 18,
        'active_rooms': 15,
        'total_rooms': 20,
        'chart_data': [
          {'label': 'Sen', 'value': 1200000},
          {'label': 'Sel', 'value': 1500000},
          {'label': 'Rab', 'value': 1800000},
          {'label': 'Kam', 'value': 1600000},
          {'label': 'Jum', 'value': 2100000},
          {'label': 'Sab', 'value': 2500000},
          {'label': 'Min', 'value': 2300000},
        ],
        'recent_payments': [
          {
            'id': '1',
            'nama_penyewa': 'Budi Santoso',
            'jumlah': 1500000,
            'tanggal': '10 Des 2024',
          },
          {
            'id': '2',
            'nama_penyewa': 'Ani Wijaya',
            'jumlah': 2000000,
            'tanggal': '9 Des 2024',
          },
          {
            'id': '3',
            'nama_penyewa': 'Citra Dewi',
            'jumlah': 1800000,
            'tanggal': '8 Des 2024',
          },
        ],
      },
    };
  }

  // =====================
  // PEMBAYARAN
  // =====================

  static Future<Map<String, dynamic>> createPembayaran(
    String token,
    Map<String, dynamic> data,
  ) => _postJson('/pembayaran', token, data);

  static Future<Map<String, dynamic>> updatePembayaranStatus(
    String token,
    String pembayaranId,
    String status,
  ) => _putJson('/pembayaran/$pembayaranId/status', token, {'status': status});

  // =====================
  // FAVORIT
  // =====================

  static Future<Map<String, dynamic>> addFavorit(String token, String kostId) =>
      _postJson('/favorit', token, {'kost_id': kostId});

  static Future<Map<String, dynamic>> removeFavorit(
    String token,
    String favoritId,
  ) => _deleteJson('/favorit/$favoritId', token);

  // =====================
  // KONTRAK
  // =====================

  static Future<Map<String, dynamic>> createKontrak(
    String token,
    Map<String, dynamic> data,
  ) => _postJson('/kontrak', token, data);

  static Future<Map<String, dynamic>> updateKontrak(
    String token,
    String kontrakId,
    Map<String, dynamic> data,
  ) => _putJson('/kontrak/$kontrakId', token, data);

  // =====================
  // USERS
  // =====================

  static Future<Map<String, dynamic>> fetchUserProfile(String token) =>
      _getJson('/users/profile', token);

  static Future<Map<String, dynamic>> updateUserProfile(
    String token,
    Map<String, dynamic> data,
  ) => _putJson('/users/profile', token, data);

  static Future<Map<String, dynamic>> changePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) => _putJson('/users/password', token, {
    'old_password': oldPassword,
    'new_password': newPassword,
  });

  // =========================
  // Predefined fetches
  // =========================
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
}