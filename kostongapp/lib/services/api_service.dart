import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // --- AUTH API ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> register(
      String nama, String email, String password, String noHp, String role) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_lengkap': nama,
          'email': email,
          'password': password,
          'no_telepon': noHp,
          'role': role,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> fetchUserProfile(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile(String token, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  // --- KOST API ---
  static Future<Map<String, dynamic>> fetchKost(String? token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/kost'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> createKost(String token, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/kost'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> updateKost(String token, String id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/kost/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> deleteKost(String token, String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/kost/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  // --- ROOMS API ---
  static Future<Map<String, dynamic>> fetchRoomsByKost(String token, String kostId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/rooms/kost/$kostId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> createRoom(String token, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> updateRoom(String token, String id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/rooms/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> deleteRoom(String token, String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/rooms/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  // --- BOOKING API ---
  static Future<Map<String, dynamic>> fetchBooking(String? token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/booking'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<List<BookingModel>> fetchUserBookings(String token, String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/booking/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => BookingModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createBooking(String token, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/booking'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> updateBookingStatus(String token, String bookingId, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/booking/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  // --- REVIEW API ---
  static Future<Map<String, dynamic>> fetchReviews(String kostId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/review/kost/$kostId'));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> fetchReview(String token) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'success': true, 'data': []}; 
  }

  static Future<Map<String, dynamic>> createReview(String token, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> deleteReview(String token, String reviewId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'success': true, 'message': 'Review deleted'};
  }

  static Future<Map<String, dynamic>> replyToReview(String token, String reviewId, String reply) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'success': true, 'message': 'Reply added'};
  }

  // --- MESSAGE API ---
  static Future<Map<String, dynamic>> fetchChatRooms(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/messages/rooms'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> fetchMessages(String token, String kostId, String user1Id, String user2Id) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/messages/$kostId/$user1Id/$user2Id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  static Future<Map<String, dynamic>> sendMessage(String token, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal'};
    }
  }

  // --- OTHER APIs ---
  static Future<Map<String, dynamic>> fetchPembayaran(String? token) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'success': true, 'data': []};
  }

  static Future<Map<String, dynamic>> fetchStatistics(String token) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'success': true,
      'data': {
        'total_pendapatan': 15000000,
        'total_booking': 25,
        'okupansi': 85,
        'rating_rata_rata': 4.8,
        'pendapatan_bulanan': [2000000, 3500000, 4000000, 5500000],
        'booking_status': {'pending': 5, 'active': 15, 'cancelled': 5}
      }
    };
  }

  static Future<Map<String, dynamic>> fetchFavorit(String? token) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'success': true, 'data': []};
  }

  static Future<Map<String, dynamic>> fetchRiwayat(String? token) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'success': true, 'data': []};
  }
}
