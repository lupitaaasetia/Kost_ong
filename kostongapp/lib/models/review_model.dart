import 'dart:math'; // Diperlukan jika ingin menggunakan random, tapi di sini kita pakai logika ID

// --- CLASS MODEL DATA ---

class ReviewReply {
  final String userName;
  final String userImage;
  final String content;
  final String date;
  final bool isOwner;

  ReviewReply({
    required this.userName,
    required this.userImage,
    required this.content,
    required this.date,
    this.isOwner = false,
  });
}

class Review {
  final String id;
  final String userName;
  final String userImage;
  final double rating;
  final String date;
  final String content;
  int likes;
  bool isLiked;
  List<ReviewReply> replies;

  Review({
    required this.id,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.date,
    required this.content,
    this.likes = 0,
    this.isLiked = false,
    this.replies = const [],
  });
}

// --- SERVICE UNTUK GENERATE DUMMY DATA ---

class ReviewService {
  // Method static ini yang dipanggil di ReviewScreen
  static List<Review> getReviewsForKost(String kostId) {
    
    int idInt = 0;
    try {
      // Mengambil hanya angka dari string ID, lalu dimodulo 4 untuk mendapatkan index 0-3
      idInt = int.parse(kostId.replaceAll(RegExp(r'[^0-9]'), '')) % 4; 
    } catch (e) {
      // Fallback jika ID tidak mengandung angka
      idInt = kostId.hashCode % 4;
    }

    // Mengembalikan data berbeda berdasarkan hasil perhitungan ID tadi
    switch (idInt) {
      case 0: // Skenario: Kost Sangat Bagus & Populer
        return [
          Review(
            id: 'r1',
            userName: 'Putri Mahardika',
            userImage: 'https://i.pravatar.cc/150?img=5',
            rating: 5.0,
            date: '2 Hari lalu',
            content: 'Kamar mandinya bersih banget, air lancar jaya. Ibu kostnya juga suka kasih makanan. Best banget pokoknya!',
            likes: 15,
            replies: [
               ReviewReply(userName: 'Ibu Kost', userImage: 'https://i.pravatar.cc/150?img=1', content: 'Makasih neng Putri, betah-betah ya!', date: '1 Hari lalu', isOwner: true),
            ]
          ),
          Review(
            id: 'r2',
            userName: 'Dedi Corbuzier',
            userImage: 'https://i.pravatar.cc/150?img=11',
            rating: 5.0,
            date: '1 Minggu lalu',
            content: 'Gym dekat sini, mantap buat olah raga pagi. Parkiran luas buat mobil, keamanan 24 jam oke.',
            likes: 8,
          ),
          Review(
            id: 'r2b',
            userName: 'Sarah Wijayanto',
            userImage: 'https://i.pravatar.cc/150?img=20',
            rating: 4.0,
            date: '2 Minggu lalu',
            content: 'Suasana tenang, cocok buat yang butuh fokus skripsi.',
            likes: 3,
          ),
        ];
      
      case 1: // Skenario: Kost Biasa Saja (Ada plus minus)
        return [
          Review(
            id: 'r3',
            userName: 'Siti Badriah',
            userImage: 'https://i.pravatar.cc/150?img=9',
            rating: 4.0,
            date: '3 Hari lalu',
            content: 'Lingkungan nyaman, cuma agak berisik kalau ada yang lewat lorong karena pintunya kurang kedap suara.',
            likes: 2,
          ),
          Review(
            id: 'r4',
            userName: 'Joko Anwar',
            userImage: 'https://i.pravatar.cc/150?img=8',
            rating: 3.0,
            date: '1 Bulan lalu',
            content: 'WiFi sering putus nyambung pas hujan deras. Mohon diperbaiki jaringannya.',
            likes: 1,
             replies: [
               ReviewReply(userName: 'Admin', userImage: 'https://i.pravatar.cc/150?img=1', content: 'Halo kak, teknisi provider sudah kami hubungi untuk perbaikan.', date: '3 Minggu lalu', isOwner: true),
            ]
          ),
        ];

      case 2: // Skenario: Kost Murah / Budget
        return [
           Review(
            id: 'r5',
            userName: 'Bambang Pamungkas',
            userImage: 'https://i.pravatar.cc/150?img=12',
            rating: 4.0,
            date: '5 Hari lalu',
            content: 'Sesuai harga lah, murah meriah. Yang penting bisa tidur nyenyak dan dekat tempat kerja.',
            likes: 5,
          ),
           Review(
            id: 'r5b',
            userName: 'Agus Kotak',
            userImage: 'https://i.pravatar.cc/150?img=33',
            rating: 3.0,
            date: '1 Minggu lalu',
            content: 'Kasurnya agak keras, mungkin perlu diganti.',
            likes: 0,
          ),
        ];

      default: // Skenario Default (Review Umum)
        return [
          Review(
            id: 'r7',
            userName: 'Anonim',
            userImage: 'https://i.pravatar.cc/150?img=60',
            rating: 4.5,
            date: '1 Hari lalu',
            content: 'Overall oke, akses kunci 24 jam jadi nilai plus buat yang pulang malam.',
            likes: 3,
          ),
        ];
    }
  }
}