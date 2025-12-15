import 'dart:async';
import '../models/chat_model.dart';

class ChatService {
  static final Map<String, List<ChatMessage>> _messages = {};
  static final Map<String, ChatRoom> _chatRooms = {};

  static final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  static Stream<ChatMessage> get messageStream => _messageController.stream;

  static ChatRoom getOrCreateChatRoom({
    required String kostId,
    required String kostName,
    required String ownerId,
    required String ownerName,
    required String seekerId,
    required String seekerName,
  }) {
    final roomId = '${kostId}_${seekerId}';

    if (_chatRooms.containsKey(roomId)) {
      return _chatRooms[roomId]!;
    }

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
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: imageUrl,
    );

    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }

    _messages[roomId]!.add(chatMessage);

    _messageController.add(chatMessage);

    if (_chatRooms.containsKey(roomId)) {
      final room = _chatRooms[roomId]!;
      final currentMessages = _messages[roomId] ?? [];

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

    await Future.delayed(const Duration(milliseconds: 100));
  }

  static List<ChatMessage> getMessages(String roomId) {
    return _messages[roomId] ?? [];
  }

  static List<ChatRoom> getChatRoomsForUser(String userId) {
    final rooms = _chatRooms.values
        .where((room) => room.seekerId == userId || room.ownerId == userId)
        .toList();

    for (var i = 0; i < rooms.length; i++) {
      final msgs = _messages[rooms[i].id] ?? [];

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

    rooms.sort((a, b) {
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return -1;
      return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
    });

    return rooms;
  }

  static void markAsRead(String roomId, String userId) {
    if (_messages.containsKey(roomId)) {
      final msgs = _messages[roomId]!;
      bool hasChanges = false;

      for (var i = 0; i < msgs.length; i++) {
        if (msgs[i].receiverId == userId && msgs[i].isRead == false) {
          msgs[i] = ChatMessage(
            id: msgs[i].id,
            roomId: msgs[i].roomId,
            senderId: msgs[i].senderId,
            senderName: msgs[i].senderName,
            receiverId: msgs[i].receiverId,
            message: msgs[i].message,
            timestamp: msgs[i].timestamp,
            isRead: true,
            imageUrl: msgs[i].imageUrl,
          );
          hasChanges = true;
        }
      }

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
          unreadCount: 0,
        );
      }
    }
  }

  static int getUnreadMessageCount(String userId) {
    int totalUnread = 0;

    final userRooms = _chatRooms.values.where(
      (room) => room.seekerId == userId || room.ownerId == userId,
    );

    for (var room in userRooms) {
      final msgs = _messages[room.id] ?? [];
      final count = msgs
          .where((m) => m.receiverId == userId && (m.isRead == false))
          .length;
      totalUnread += count;
    }

    return totalUnread;
  }

  static void clearAll() {
    _messages.clear();
    _chatRooms.clear();
  }
}
