class BookingModel {
  final String id;
  final String idKost;
  final String idUser;
  final String tanggalMasuk;
  final String durasiSewa;
  final int totalHarga;
  final String statusPembayaran;
  final String statusBooking;
  final String? namaKost; 
  final String? alamatKost;

  BookingModel({
    required this.id,
    required this.idKost,
    required this.idUser,
    required this.tanggalMasuk,
    required this.durasiSewa,
    required this.totalHarga,
    required this.statusPembayaran,
    required this.statusBooking,
    this.namaKost,
    this.alamatKost,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Helper aman untuk string
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    // Helper aman untuk int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Handle id_kost (bisa string atau object)
    String kostId = '';
    String kostName = 'Kost';
    String kostAddress = '-';

    if (json['kost_id'] != null) { // Cek field kost_id (sesuai schema baru)
       if (json['kost_id'] is Map) {
        kostId = safeString(json['kost_id']['_id']);
        kostName = safeString(json['kost_id']['nama_kost']);
        kostAddress = safeString(json['kost_id']['alamat']);
      } else {
        kostId = safeString(json['kost_id']);
      }
    } else if (json['id_kost'] != null) { // Fallback ke id_kost
       if (json['id_kost'] is Map) {
        kostId = safeString(json['id_kost']['_id']);
        kostName = safeString(json['id_kost']['nama_kost']);
        kostAddress = safeString(json['id_kost']['alamat']);
      } else {
        kostId = safeString(json['id_kost']);
      }
    }

    // Handle id_user (bisa string atau object)
    String userId = '';
    if (json['user_id'] != null) {
       if (json['user_id'] is Map) {
        userId = safeString(json['user_id']['_id']);
      } else {
        userId = safeString(json['user_id']);
      }
    } else if (json['id_user'] != null) {
       if (json['id_user'] is Map) {
        userId = safeString(json['id_user']['_id']);
      } else {
        userId = safeString(json['id_user']);
      }
    }

    // Handle status (prioritas status_booking)
    String status = safeString(json['status_booking']);
    if (status.isEmpty) status = safeString(json['status']);
    if (status.isEmpty) status = 'pending';

    return BookingModel(
      id: safeString(json['_id']),
      idKost: kostId,
      idUser: userId,
      tanggalMasuk: safeString(json['tanggal_mulai'] ?? json['tanggal_masuk']),
      durasiSewa: safeString(json['durasi'] ?? json['durasi_sewa']),
      totalHarga: safeInt(json['total_bayar'] ?? json['total_harga'] ?? json['total']),
      statusPembayaran: safeString(json['metode_pembayaran']),
      statusBooking: status,
      namaKost: kostName,
      alamatKost: kostAddress,
    );
  }
}
