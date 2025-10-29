// services/notification_service.dart
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  bool _initialized = false;

  void initialize(String userEmail) {
    if (_initialized) return;

    // Demo notifications
    _notifications.addAll([
      AppNotification(
        id: 'notif_001',
        userId: userEmail,
        title: 'Pembayaran Berhasil! 🎉',
        message:
            'Pembayaran booking Kost Putri Melati telah dikonfirmasi. Kontrak sewa Anda sudah siap.',
        type: NotificationType.payment,
        relatedId: 'booking_001',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_002',
        userId: userEmail,
        title: 'Booking Dikonfirmasi',
        message:
            'Booking Anda untuk Kost Putra Mentari telah dikonfirmasi oleh pemilik kost.',
        type: NotificationType.booking,
        relatedId: 'booking_002',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_003',
        userId: userEmail,
        title: 'Reminder Check-in',
        message:
            'Jangan lupa! Check-in Anda di Kost Putri Melati dijadwalkan besok pukul 10:00 WIB.',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_004',
        userId: userEmail,
        title: 'Review Booking Anda',
        message:
            'Bagaimana pengalaman Anda di Kost Putra Mawar? Berikan review untuk membantu pengguna lain.',
        type: NotificationType.review,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_005',
        userId: userEmail,
        title: 'Promo Diskon 15% 🎁',
        message:
            'Dapatkan diskon 15% untuk booking minimal 6 bulan! Berlaku hingga akhir bulan.',
        type: NotificationType.promotion,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_006',
        userId: userEmail,
        title: 'Pesan dari Pemilik Kost',
        message:
            'Bu Ani (Pemilik Kost Putri Melati): "Selamat datang! Jika ada pertanyaan, hubungi saya ya."',
        type: NotificationType.chat,
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_007',
        userId: userEmail,
        title: 'Deposit Dikembalikan',
        message:
            'Deposit Rp 800.000 untuk Kost Putra Mawar telah dikembalikan ke rekening Anda.',
        type: NotificationType.payment,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        isRead: true,
      ),
    ]);

    _initialized = true;
  }

  List<AppNotification> getNotifications(String userEmail) {
    if (!_initialized) {
      initialize(userEmail);
    }
    return List.from(_notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<AppNotification> getUnreadNotifications(String userEmail) {
    return getNotifications(userEmail).where((n) => !n.isRead).toList();
  }

  int getUnreadCount(String userEmail) {
    return getUnreadNotifications(userEmail).length;
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  void markAllAsRead(String userEmail) {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userEmail) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
  }

  // Helper untuk create notification
  void createBookingNotification(String userEmail, String kostName) {
    addNotification(
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: userEmail,
        title: 'Booking Berhasil',
        message:
            'Booking Anda untuk $kostName telah dibuat. Lanjutkan pembayaran untuk konfirmasi.',
        type: NotificationType.booking,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void createPaymentNotification(String userEmail, String kostName) {
    addNotification(
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: userEmail,
        title: 'Pembayaran Berhasil! 🎉',
        message:
            'Pembayaran untuk $kostName telah dikonfirmasi. Kontrak sewa Anda sudah siap.',
        type: NotificationType.payment,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void createSystemNotification(
    String userEmail,
    String title,
    String message,
  ) {
    addNotification(
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: userEmail,
        title: title,
        message: message,
        type: NotificationType.system,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }
}
