class BookingModel {
  final String id;
  final String idKost;
  final String idUser;
  final String tanggalMasuk;
  final String durasiSewa;
  final int totalHarga;
  final String statusPembayaran;
  final String statusBooking;
  // Field tambahan untuk menampung data kost yang di-populate (opsional tapi penting buat UI)
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
    // Cek apakah id_kost berupa object (popualted) atau string biasa
    String kostId = '';
    String kostName = 'Kost';
    String kostAddress = '-';

    if (json['id_kost'] is Map) {
      kostId = json['id_kost']['_id'] ?? '';
      kostName = json['id_kost']['nama_kost'] ?? 'Nama Kost';
      kostAddress = json['id_kost']['alamat'] ?? '-';
    } else {
      kostId = json['id_kost'].toString();
    }

    return BookingModel(
      id: json['_id'],
      idKost: kostId,
      idUser: json['id_user'],
      tanggalMasuk: json['tanggal_masuk'] ?? '',
      durasiSewa: json['durasi_sewa'].toString(),
      totalHarga: json['total_harga'] ?? 0,
      statusPembayaran: json['status_pembayaran'] ?? 'pending',
      statusBooking: json['status_booking'] ?? 'menunggu',
      namaKost: kostName,
      alamatKost: kostAddress,
    );
  }
}