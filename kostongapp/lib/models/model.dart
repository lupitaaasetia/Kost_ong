class User {
  String? id;
  String namaLengkap;
  String email;
  String noTelepon;
  String role; // 'pemilik' atau 'pencari'
  String? password;
  String? jenisKelamin;
  DateTime? tanggalLahir;
  Alamat? alamat;
  String? ktp;
  bool verified;

  User({
    this.id,
    required this.namaLengkap,
    required this.email,
    required this.noTelepon,
    required this.role,
    this.password,
    this.jenisKelamin,
    this.tanggalLahir,
    this.alamat,
    this.ktp,
    this.verified = false,
  });

  // Helper untuk menghandle format $oid dan $date dari Raw Mongo atau String biasa dari API
  static String? _parseId(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is Map && json.containsKey('\$oid')) return json['\$oid'];
    return json.toString();
  }

  static DateTime? _parseDate(dynamic json) {
    if (json == null) return null;
    if (json is String) return DateTime.tryParse(json);
    if (json is Map && json.containsKey('\$date')) return DateTime.tryParse(json['\$date']);
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseId(json['_id']),
      namaLengkap: json['nama_lengkap'] ?? '',
      email: json['email'] ?? '',
      noTelepon: json['no_telepon'] ?? '',
      role: json['role'] ?? 'pencari',
      jenisKelamin: json['jenis_kelamin'],
      tanggalLahir: _parseDate(json['tanggal_lahir']),
      alamat: json['alamat'] != null ? Alamat.fromJson(json['alamat']) : null,
      ktp: json['ktp'],
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_telepon': noTelepon,
      'role': role,
    };
    if (password != null) data['password'] = password;
    if (alamat != null) data['alamat'] = alamat!.toJson();
    return data;
  }
}

class Kost {
  String? id;
  String? pemilikId;
  String namaKost;
  String deskripsi;
  String tipeKost;
  Alamat? alamat;
  List<String> fasilitasUmum;
  List<String> fasilitasKamar;
  double rating;
  int jumlahReview;
  List<String> fotoKost;
  int harga; // Menambahkan field harga yang biasanya penting

  Kost({
    this.id,
    this.pemilikId,
    required this.namaKost,
    required this.deskripsi,
    required this.tipeKost,
    this.alamat,
    this.fasilitasUmum = const [],
    this.fasilitasKamar = const [],
    this.rating = 0.0,
    this.jumlahReview = 0,
    this.fotoKost = const [],
    this.harga = 0,
  });

  factory Kost.fromJson(Map<String, dynamic> json) {
    return Kost(
      id: User._parseId(json['_id']),
      pemilikId: User._parseId(json['pemilik_id']),
      namaKost: json['nama_kost'] ?? 'Tanpa Nama',
      deskripsi: json['deskripsi'] ?? '',
      tipeKost: json['tipe_kost'] ?? 'Campur',
      alamat: json['alamat'] != null ? Alamat.fromJson(json['alamat']) : null,
      fasilitasUmum: json['fasilitas_umum'] != null ? List<String>.from(json['fasilitas_umum']) : [],
      fasilitasKamar: json['fasilitas_kamar_default'] != null ? List<String>.from(json['fasilitas_kamar_default']) : [],
      rating: (json['rating'] ?? 0).toDouble(),
      jumlahReview: json['jumlah_review'] ?? 0,
      fotoKost: json['foto_kost'] != null ? List<String>.from(json['foto_kost']) : [],
      harga: json['harga_per_bulan'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_kost': namaKost,
      'deskripsi': deskripsi,
      'tipe_kost': tipeKost,
      'fasilitas_umum': fasilitasUmum,
      'fasilitas_kamar_default': fasilitasKamar,
      if (alamat != null) 'alamat': alamat!.toJson(),
      'harga_per_bulan': harga,
    };
  }
}

class Alamat {
  String? jalan;
  String? kota;
  String? provinsi;

  Alamat({this.jalan, this.kota, this.provinsi});

  factory Alamat.fromJson(Map<String, dynamic> json) {
    return Alamat(
      jalan: json['jalan'],
      kota: json['kota'],
      provinsi: json['provinsi'],
    );
  }

  Map<String, dynamic> toJson() => {
    'jalan': jalan,
    'kota': kota,
    'provinsi': provinsi,
  };
}