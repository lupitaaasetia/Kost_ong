// services/chat_service.dart
import 'dart:async';
import '../models/chat.dart';

class ChatService {
  // Simpan data di memori (Static)
  static final Map<String, List<ChatMessage>> _messages = {};
  static final Map<String, ChatRoom> _chatRooms = {};

  // Stream controller untuk mendengarkan pesan baru secara real-time
  static final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  // Getter stream
  static Stream<ChatMessage> get messageStream => _messageController.stream;

  // Create or get chat room
  static ChatRoom getOrCreateChatRoom({
    required String kostId,
    required String kostName,
    required String ownerId,
    required String ownerName,
    required String seekerId,
    required String seekerName,
  }) {
    final roomId = '${kostId}_${seekerId}';

    // Jika room sudah ada, kembalikan yang ada
    if (_chatRooms.containsKey(roomId)) {
      return _chatRooms[roomId]!;
    }

    // Jika belum ada, buat baru
    final room = ChatRoom(
      id: roomId,
      kostId: kostId,
      kostName: kostName,
      ownerId: ownerId,
      ownerName: ownerName,
      seekerId: seekerId,
      seekerName: seekerName,
      messages: _messages[roomId] ?? [],
      unreadCount: 0,
      lastMessage: null,
    );

    _chatRooms[roomId] = room;
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }

    return room;
  }

  // Send message
  static Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: imageUrl,
    );

    // Inisialisasi list pesan jika belum ada
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }

    // Tambah pesan ke memori
    _messages[roomId]!.add(chatMessage);

    // Broadcast ke stream
    _messageController.add(chatMessage);

    // Update metadata ChatRoom
    if (_chatRooms.containsKey(roomId)) {
      final room = _chatRooms[roomId]!;
      final currentMessages = _messages[roomId] ?? [];

      // Update Unread Count: Tambah 1 jika yang mengirim bukan pemilik sesi saat ini (logika sederhana)
      // Catatan: Logic unread count biasanya dihandle sisi penerima, tapi untuk mock ini kita update object room.
      int newUnread = room.unreadCount + 1;

      _chatRooms[roomId] = ChatRoom(
        id: room.id,
        kostId: room.kostId,
        kostName: room.kostName,
        ownerId: room.ownerId,
        ownerName: room.ownerName,
        seekerId: room.seekerId,
        seekerName: room.seekerName,
        messages: currentMessages,
        lastMessage: chatMessage,
        unreadCount: newUnread,
      );
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Get messages for a chat room
  static List<ChatMessage> getMessages(String roomId) {
    return _messages[roomId] ?? [];
  }

  // Get all chat rooms for a user
  static List<ChatRoom> getChatRoomsForUser(String userId) {
    // Ambil room di mana user terlibat sebagai seeker atau owner
    final rooms = _chatRooms.values
        .where((room) => room.seekerId == userId || room.ownerId == userId)
        .toList();

    // Perbarui data pesan di dalam setiap room object sebelum dikembalikan
    for (var i = 0; i < rooms.length; i++) {
      final msgs = _messages[rooms[i].id] ?? [];

      // Hitung unread count spesifik untuk user ini
      // (Pesan yang DITERIMA oleh user ini dan status isRead = false)
      final unreadForMe = msgs
          .where((m) => m.receiverId == userId && (m.isRead == false))
          .length;

      rooms[i] = ChatRoom(
        id: rooms[i].id,
        kostId: rooms[i].kostId,
        kostName: rooms[i].kostName,
        ownerId: rooms[i].ownerId,
        ownerName: rooms[i].ownerName,
        seekerId: rooms[i].seekerId,
        seekerName: rooms[i].seekerName,
        messages: msgs,
        lastMessage: msgs.isNotEmpty ? msgs.last : null,
        unreadCount: unreadForMe,
      );
    }

    // Sort berdasarkan waktu pesan terakhir (terbaru di atas)
    rooms.sort((a, b) {
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return -1;
      return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
    });

    return rooms;
  }

  // Mark messages as read
  static void markAsRead(String roomId, String userId) {
    if (_messages.containsKey(roomId)) {
      final msgs = _messages[roomId]!;
      bool hasChanges = false;

      // Update status isRead pada list pesan
      for (var i = 0; i < msgs.length; i++) {
        if (msgs[i].receiverId == userId && msgs[i].isRead == false) {
          msgs[i] = ChatMessage(
            id: msgs[i].id,
            senderId: msgs[i].senderId,
            senderName: msgs[i].senderName,
            receiverId: msgs[i].receiverId,
            message: msgs[i].message,
            timestamp: msgs[i].timestamp,
            isRead: true, // Ubah jadi true
            imageUrl: msgs[i].imageUrl,
          );
          hasChanges = true;
        }
      }

      // Jika ada perubahan, update ChatRoom untuk reset counter
      if (hasChanges && _chatRooms.containsKey(roomId)) {
        final room = _chatRooms[roomId]!;
        _chatRooms[roomId] = ChatRoom(
          id: room.id,
          kostId: room.kostId,
          kostName: room.kostName,
          ownerId: room.ownerId,
          ownerName: room.ownerName,
          seekerId: room.seekerId,
          seekerName: room.seekerName,
          messages: msgs,
          lastMessage: room.lastMessage,
          unreadCount: 0, // Reset counter tampilan user ini
        );
      }
    }
  }

  // Get total unread count for user (untuk Badge di BottomNav)
  static int getUnreadMessageCount(String userId) {
    int totalUnread = 0;

    // Loop semua room yang melibatkan user
    final userRooms = _chatRooms.values.where(
      (room) => room.seekerId == userId || room.ownerId == userId,
    );

    for (var room in userRooms) {
      final msgs = _messages[room.id] ?? [];
      // Hitung pesan yang belum dibaca yang ditujukan ke user ini
      final count = msgs
          .where((m) => m.receiverId == userId && (m.isRead == false))
          .length;
      totalUnread += count;
    }

    return totalUnread;
  }

  // Clear all data (for testing/logout)
  static void clearAll() {
    _messages.clear();
    _chatRooms.clear();
    // Note: StreamController tidak diclose karena static dan mungkin dipakai lagi setelah re-login tanpa restart app
  }
}
