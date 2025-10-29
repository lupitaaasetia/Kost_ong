import 'kost.dart';

enum BookingStatus {
  pending('Menunggu Konfirmasi'),
  confirmed('Disetujui'),
  rejected('Ditolak'),
  completed('Lengkap'),
  cancelled('Dibatalkan'),
  paid('Sudah Dibayar'),
  active('Aktif');

  final String displayName;
  const BookingStatus(this.displayName);
}

enum PaymentStatus { pending, paid, failed, refunded }

enum PaymentMethod { bankTransfer, eWallet, creditCard, cash }

class RoomDetail {
  final String roomNumber;
  final String floor;
  final double size; // in square meters
  final bool hasWindow;
  final String bedType;

  RoomDetail({
    required this.roomNumber,
    required this.floor,
    required this.size,
    required this.hasWindow,
    required this.bedType,
  });
}

class Booking {
  final String id;
  final BaseKost kost;
  final String userEmail;
  final RoomDetail roomDetail;
  final DateTime bookingDate;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int duration; // in months
  final double totalPrice;
  final double depositAmount;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.kost,
    required this.userEmail,
    required this.roomDetail,
    required this.bookingDate,
    required this.checkInDate,
    required this.checkOutDate,
    required this.duration,
    required this.totalPrice,
    required this.depositAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
  });

  String getStatusText() {
    switch (status) {
      case BookingStatus.pending:
        return 'Menunggu Konfirmasi';
      case BookingStatus.confirmed:
        return 'Terkonfirmasi';
      case BookingStatus.rejected:
        return 'Ditolak';
      case BookingStatus.paid:
        return 'Sudah Dibayar';
      case BookingStatus.active:
        return 'Sedang Aktif';
      case BookingStatus.completed:
        return 'Selesai';
      case BookingStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String getPaymentStatusText() {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Menunggu Pembayaran';
      case PaymentStatus.paid:
        return 'Sudah Dibayar';
      case PaymentStatus.failed:
        return 'Gagal';
      case PaymentStatus.refunded:
        return 'Dikembalikan';
    }
  }
}

class Payment {
  final String id;
  final String bookingId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime paymentDate;
  final String? proofImagePath;
  final String? transactionId;
  final String? notes;

  Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paymentDate,
    this.proofImagePath,
    this.transactionId,
    this.notes,
  });

  String getMethodText() {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
      case PaymentMethod.creditCard:
        return 'Kartu Kredit';
      case PaymentMethod.cash:
        return 'Tunai';
    }
  }
}

class Review {
  final String id;
  final String kostId;
  final String userEmail;
  final String userName;
  final double rating;
  final String comment;
  final List<String> pros;
  final List<String> cons;
  final DateTime createdAt;
  final bool isVerified; // User pernah ngekost disini

  Review({
    required this.id,
    required this.kostId,
    required this.userEmail,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.pros,
    required this.cons,
    required this.createdAt,
    required this.isVerified,
  });
}

class Contract {
  final String id;
  final String bookingId;
  final String contractNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String terms;
  final String landlordName;
  final String tenantName;
  final DateTime signedDate;
  final String pdfPath;

  Contract({
    required this.id,
    required this.bookingId,
    required this.contractNumber,
    required this.startDate,
    required this.endDate,
    required this.terms,
    required this.landlordName,
    required this.tenantName,
    required this.signedDate,
    required this.pdfPath,
  });
}
