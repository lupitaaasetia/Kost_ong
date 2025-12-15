import 'dart:math';

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
  static List<Review> getReviewsForKost(String kostId) {
    
    int idInt = 0;
    try {
      idInt = int.parse(kostId.replaceAll(RegExp(r'[^0-9]'), '')) % 5; 
    } catch (e) {
      idInt = kostId.hashCode % 5;
    }

    switch (idInt) {
      case 0: // Skenario Kost A: Sangat Bagus
        return [
          Review(
            id: 'r1',
            userName: 'Putri Mahardika',
            userImage: 'https://picsum.photos/seed/putri/150',
            rating: 5.0,
            date: '2 Hari lalu',
            content: 'Kamar mandinya bersih banget, air lancar jaya. Ibu kostnya juga suka kasih makanan.',
            likes: 15,
            replies: [
               ReviewReply(userName: 'Ibu Kost', userImage: 'https://picsum.photos/seed/ibukost/150', content: 'Makasih neng Putri!', date: '1 Hari lalu', isOwner: true),
            ]
          ),
          Review(
            id: 'r2',
            userName: 'Dedi Corbuzier',
            userImage: 'https://picsum.photos/seed/dedi/150',
            rating: 5.0,
            date: '1 Minggu lalu',
            content: 'Gym dekat sini, mantap buat olah raga pagi. Parkiran luas buat mobil.',
            likes: 8,
          ),
        ];
      
      case 1: // Skenario Kost B: Standar
        return [
          Review(
            id: 'r3',
            userName: 'Siti Badriah',
            userImage: 'https://picsum.photos/seed/siti/150',
            rating: 4.0,
            date: '3 Hari lalu',
            content: 'Lingkungan nyaman, cuma agak berisik kalau ada yang lewat lorong.',
            likes: 2,
          ),
          Review(
            id: 'r4',
            userName: 'Joko Anwar',
            userImage: 'https://picsum.photos/seed/joko/150',
            rating: 3.0,
            date: '1 Bulan lalu',
            content: 'WiFi sering putus nyambung pas hujan.',
            likes: 0,
             replies: [
               ReviewReply(userName: 'Pemilik', userImage: 'https://picsum.photos/seed/pemilik/150', content: 'Maaf mas, teknisi sudah kami panggil.', date: '3 Minggu lalu', isOwner: true),
            ]
          ),
        ];

      case 2: // Skenario Kost C: Murah Meriah
        return [
           Review(
            id: 'r5',
            userName: 'Bambang Pamungkas',
            userImage: 'https://picsum.photos/seed/bambang/150',
            rating: 4.0,
            date: '5 Hari lalu',
            content: 'Sesuai harga lah, yang penting bisa tidur nyenyak.',
            likes: 5,
          ),
        ];

      case 3: // Skenario Kost D: Baru Buka (Belum banyak review)
         return [
           Review(
            id: 'r6',
            userName: 'Rina Nose',
            userImage: 'https://picsum.photos/seed/rina/150',
            rating: 5.0,
            date: 'Baru saja',
            content: 'Wah kost baru, perabotannya masih wangi toko. Suka banget desainnya!',
            likes: 1,
          ),
        ];

      default: // Skenario Default
        return [
          Review(
            id: 'r7',
            userName: 'Anonim',
            userImage: 'https://picsum.photos/seed/anonim/150',
            rating: 4.5,
            date: '1 Hari lalu',
            content: 'Overall oke, akses 24 jam jadi nilai plus.',
            likes: 3,
          ),
        ];
    }
  }
}
