import 'dart:math';
import '../models/booking.dart';
import '../models/kost.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final List<Booking> _bookings = [];
  final List<Payment> _payments = [];
  final List<Review> _reviews = [];
  final List<Contract> _contracts = [];
  final List<String> _favorites = [];

  // Available rooms untuk demo
  final List<RoomDetail> _availableRooms = [
    RoomDetail(
      roomNumber: 'A101',
      floor: 'Lantai 1',
      size: 12.5,
      hasWindow: true,
      bedType: 'Single Bed',
    ),
    RoomDetail(
      roomNumber: 'A102',
      floor: 'Lantai 1',
      size: 15.0,
      hasWindow: true,
      bedType: 'Double Bed',
    ),
    RoomDetail(
      roomNumber: 'B201',
      floor: 'Lantai 2',
      size: 14.0,
      hasWindow: true,
      bedType: 'Single Bed',
    ),
    RoomDetail(
      roomNumber: 'B202',
      floor: 'Lantai 2',
      size: 16.5,
      hasWindow: false,
      bedType: 'Double Bed',
    ),
    RoomDetail(
      roomNumber: 'C301',
      floor: 'Lantai 3',
      size: 13.5,
      hasWindow: true,
      bedType: 'Single Bed',
    ),
  ];

  List<RoomDetail> getAvailableRooms() => List.from(_availableRooms);

  List<Booking> getUserBookings(String userEmail) {
    return _bookings.where((b) => b.userEmail == userEmail).toList();
  }

  List<String> getFavorites() => List.from(_favorites);

  void addFavorite(String kostId) {
    if (!_favorites.contains(kostId)) {
      _favorites.add(kostId);
    }
  }

  void removeFavorite(String kostId) {
    _favorites.remove(kostId);
  }

  bool isFavorite(String kostId) {
    return _favorites.contains(kostId);
  }

  Booking createBooking({
    required BaseKost kost,
    required String userEmail,
    required RoomDetail roomDetail,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int duration,
    String? notes,
  }) {
    final totalPrice = (kost.pricePerMonth.toDouble()) * duration;
    final depositAmount = kost.pricePerMonth.toDouble(); // 1 bulan deposit

    final booking = Booking(
      id: 'BK${DateTime.now().millisecondsSinceEpoch}',
      kost: kost,
      userEmail: userEmail,
      roomDetail: roomDetail,
      bookingDate: DateTime.now(),
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      duration: duration,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      status: BookingStatus.pending,
      paymentStatus: PaymentStatus.pending,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _bookings.add(booking);
    return booking;
  }

  Payment createPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    String? proofImagePath,
    String? notes,
  }) {
    final payment = Payment(
      id: 'PAY${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      paymentDate: DateTime.now(),
      proofImagePath: proofImagePath,
      transactionId: _generateTransactionId(),
      notes: notes,
    );

    _payments.add(payment);
    return payment;
  }

  void confirmPayment(String paymentId) {
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      // Update payment status
      final payment = _payments[index];
      final updatedPayment = Payment(
        id: payment.id,
        bookingId: payment.bookingId,
        amount: payment.amount,
        method: payment.method,
        status: PaymentStatus.paid,
        paymentDate: payment.paymentDate,
        proofImagePath: payment.proofImagePath,
        transactionId: payment.transactionId,
        notes: payment.notes,
      );
      _payments[index] = updatedPayment;

      // Update booking status
      final bookingIndex = _bookings.indexWhere(
        (b) => b.id == payment.bookingId,
      );
      if (bookingIndex != -1) {
        final booking = _bookings[bookingIndex];
        final updatedBooking = Booking(
          id: booking.id,
          kost: booking.kost,
          userEmail: booking.userEmail,
          roomDetail: booking.roomDetail,
          bookingDate: booking.bookingDate,
          checkInDate: booking.checkInDate,
          checkOutDate: booking.checkOutDate,
          duration: booking.duration,
          totalPrice: booking.totalPrice,
          depositAmount: booking.depositAmount,
          status: BookingStatus.paid,
          paymentStatus: PaymentStatus.paid,
          notes: booking.notes,
          createdAt: booking.createdAt,
        );
        _bookings[bookingIndex] = updatedBooking;

        // Generate contract
        _generateContract(updatedBooking);
      }
    }
  }

  Contract? _generateContract(Booking booking) {
    final contract = Contract(
      id: 'CTR${DateTime.now().millisecondsSinceEpoch}',
      bookingId: booking.id,
      contractNumber: 'CTR/${DateTime.now().year}/${booking.id}',
      startDate: booking.checkInDate,
      endDate: booking.checkOutDate,
      terms: _getContractTerms(),
      landlordName: 'Pemilik ${booking.kost.name}',
      tenantName: booking.userEmail.split('@')[0],
      signedDate: DateTime.now(),
      pdfPath: '/contracts/${booking.id}.pdf',
    );

    _contracts.add(contract);
    return contract;
  }

  Contract? getContractByBookingId(String bookingId) {
    try {
      return _contracts.firstWhere((c) => c.bookingId == bookingId);
    } catch (e) {
      return null;
    }
  }

  Review addReview({
    required String kostId,
    required String userEmail,
    required String userName,
    required double rating,
    required String comment,
    required List<String> pros,
    required List<String> cons,
  }) {
    // Check if user has completed booking
    final hasCompletedBooking = _bookings.any(
      (b) =>
          b.kost.id == kostId &&
          b.userEmail == userEmail &&
          (b.status == BookingStatus.completed ||
              b.status == BookingStatus.active),
    );

    final review = Review(
      id: 'REV${DateTime.now().millisecondsSinceEpoch}',
      kostId: kostId,
      userEmail: userEmail,
      userName: userName,
      rating: rating,
      comment: comment,
      pros: pros,
      cons: cons,
      createdAt: DateTime.now(),
      isVerified: hasCompletedBooking,
    );

    _reviews.add(review);
    return review;
  }

  List<Review> getReviewsByKostId(String kostId) {
    return _reviews.where((r) => r.kostId == kostId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  double getAverageRating(String kostId) {
    final reviews = getReviewsByKostId(kostId);
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold(0.0, (sum, review) => sum + review.rating);
    return sum / reviews.length;
  }

  Payment? getPaymentByBookingId(String bookingId) {
    try {
      return _payments.firstWhere((p) => p.bookingId == bookingId);
    } catch (e) {
      return null;
    }
  }

  String _generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999);
    return 'TRX$timestamp$randomNum';
  }

  String _getContractTerms() {
    return '''
SYARAT DAN KETENTUAN SEWA KOST

1. PEMBAYARAN
   - Pembayaran sewa dilakukan di muka setiap bulan
   - Deposit sebesar 1 bulan sewa wajib dibayarkan
   - Keterlambatan pembayaran dikenakan denda 2% per hari

2. FASILITAS
   - Penyewa wajib menjaga kebersihan dan kelayakan fasilitas
   - Kerusakan fasilitas menjadi tanggung jawab penyewa
   - Listrik dan air sudah termasuk dalam harga sewa

3. PERATURAN
   - Dilarang membawa tamu menginap tanpa izin
   - Dilarang keras narkoba dan minuman keras
   - Jam malam sesuai ketentuan yang berlaku
   - Dilarang membuat keributan yang mengganggu penghuni lain

4. PEMBATALAN
   - Pembatalan sewa dikenakan potongan deposit
   - Pemberitahuan pembatalan minimal 1 bulan sebelumnya
   - Deposit dikembalikan setelah verifikasi kondisi kamar

5. LAIN-LAIN
   - Penyewa wajib mematuhi semua peraturan yang berlaku
   - Pemilik berhak mengubah peraturan dengan pemberitahuan
   - Kontrak ini berlaku sesuai dengan masa sewa yang disepakati
''';
  }

  void initializeDemoReviews(List<BaseKost> kostList) {
    if (_reviews.isNotEmpty) return;

    final demoReviews = [
      Review(
        id: 'REV1',
        kostId: kostList[0].id,
        userEmail: 'user1@email.com',
        userName: 'Budi Santoso',
        rating: 4.5,
        comment:
            'Kost yang nyaman dan bersih. Pemilik sangat ramah dan responsif.',
        pros: ['Lokasi strategis', 'Kamar bersih', 'WiFi cepat'],
        cons: ['Parkir terbatas'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isVerified: true,
      ),
      Review(
        id: 'REV2',
        kostId: kostList[0].id,
        userEmail: 'user2@email.com',
        userName: 'Siti Nurhaliza',
        rating: 5.0,
        comment:
            'Sangat puas! Semua fasilitas lengkap dan terawat dengan baik.',
        pros: ['Fasilitas lengkap', 'Aman', 'Dekat kampus'],
        cons: [],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isVerified: true,
      ),
      Review(
        id: 'REV3',
        kostId: kostList[1].id,
        userEmail: 'user3@email.com',
        userName: 'Ahmad Wijaya',
        rating: 4.0,
        comment:
            'Kost yang bagus dengan harga terjangkau. Cocok untuk mahasiswa.',
        pros: ['Harga terjangkau', 'Dekat dengan fasilitas umum'],
        cons: ['Kamar mandi bersama', 'Agak berisik'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        isVerified: true,
      ),
    ];

    _reviews.addAll(demoReviews);
  }

  // Konfirmasi booking (ubah status menjadi aktif)
  void confirmBooking(String id) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final booking = _bookings[index];
      final updatedBooking = Booking(
        id: booking.id,
        kost: booking.kost,
        userEmail: booking.userEmail,
        roomDetail: booking.roomDetail,
        bookingDate: booking.bookingDate,
        checkInDate: booking.checkInDate,
        checkOutDate: booking.checkOutDate,
        duration: booking.duration,
        totalPrice: booking.totalPrice,
        depositAmount: booking.depositAmount,
        status: BookingStatus.active,
        paymentStatus: booking.paymentStatus,
        notes: booking.notes,
        createdAt: booking.createdAt,
      );

      _bookings[index] = updatedBooking;
    }
  }

  // Ambil semua data booking
  List<Booking> getAllBookings() {
    return List.unmodifiable(_bookings);
  }

  // Batalkan booking berdasarkan ID
  void cancelBooking(String id) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final booking = _bookings[index];
      final canceledBooking = Booking(
        id: booking.id,
        kost: booking.kost,
        userEmail: booking.userEmail,
        roomDetail: booking.roomDetail,
        bookingDate: booking.bookingDate,
        checkInDate: booking.checkInDate,
        checkOutDate: booking.checkOutDate,
        duration: booking.duration,
        totalPrice: booking.totalPrice,
        depositAmount: booking.depositAmount,
        status: BookingStatus.cancelled,
        paymentStatus: PaymentStatus.refunded,
        notes: booking.notes,
        createdAt: booking.createdAt,
      );

      _bookings[index] = canceledBooking;
    }
  }

  // ✅ Tambahkan method untuk menghitung jumlah booking
  int getPendingBookingsCount() {
    return _bookings.where((b) => b.status == BookingStatus.pending).length;
  }

  int getConfirmedBookingsCount() {
    return _bookings.where((b) => b.status == BookingStatus.confirmed).length;
  }

  int getPaidBookingsCount() {
    return _bookings
        .where(
          (b) =>
              b.status == BookingStatus.paid ||
              b.status == BookingStatus.active,
        )
        .length;
  }

  int getCancelledBookingsCount() {
    return _bookings.where((b) => b.status == BookingStatus.cancelled).length;
  }

  // Update booking status by id
  void updateBookingStatus(String id, BookingStatus status) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final booking = _bookings[index];
      final updatedBooking = Booking(
        id: booking.id,
        kost: booking.kost,
        userEmail: booking.userEmail,
        roomDetail: booking.roomDetail,
        bookingDate: booking.bookingDate,
        checkInDate: booking.checkInDate,
        checkOutDate: booking.checkOutDate,
        duration: booking.duration,
        totalPrice: booking.totalPrice,
        depositAmount: booking.depositAmount,
        status: status,
        paymentStatus: booking.paymentStatus,
        notes: booking.notes,
        createdAt: booking.createdAt,
      );

      _bookings[index] = updatedBooking;
    }
  }

  // Approve booking and optionally attach notes
  void approveBooking(String id, String? notes) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final booking = _bookings[index];
      final updatedBooking = Booking(
        id: booking.id,
        kost: booking.kost,
        userEmail: booking.userEmail,
        roomDetail: booking.roomDetail,
        bookingDate: booking.bookingDate,
        checkInDate: booking.checkInDate,
        checkOutDate: booking.checkOutDate,
        duration: booking.duration,
        totalPrice: booking.totalPrice,
        depositAmount: booking.depositAmount,
        status: BookingStatus.confirmed,
        paymentStatus: booking.paymentStatus,
        notes: notes ?? booking.notes,
        createdAt: booking.createdAt,
      );

      _bookings[index] = updatedBooking;
    }
  }

  // Reject booking and optionally attach notes
  void rejectBooking(String id, String? notes) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final booking = _bookings[index];
      final updatedBooking = Booking(
        id: booking.id,
        kost: booking.kost,
        userEmail: booking.userEmail,
        roomDetail: booking.roomDetail,
        bookingDate: booking.bookingDate,
        checkInDate: booking.checkInDate,
        checkOutDate: booking.checkOutDate,
        duration: booking.duration,
        totalPrice: booking.totalPrice,
        depositAmount: booking.depositAmount,
        status: BookingStatus.rejected,
        paymentStatus: booking.paymentStatus,
        notes: notes ?? booking.notes,
        createdAt: booking.createdAt,
      );

      _bookings[index] = updatedBooking;
    }
  }
}
