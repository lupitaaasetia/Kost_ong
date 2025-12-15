class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'senderId': senderId,
    'senderName': senderName,
    'receiverId': receiverId,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'imageUrl': imageUrl,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    roomId: json['roomId'] ?? '',
    senderId: json['senderId'] ?? '',
    senderName: json['senderName'] ?? '',
    receiverId: json['receiverId'] ?? '',
    message: json['message'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
    imageUrl: json['imageUrl'],
  );
}

class ChatRoom {
  final String id;
  final String kostId;
  final String kostName;
  final String ownerId;
  final String ownerName;
  final String seekerId;
  final String seekerName;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final List<ChatMessage> messages;

  ChatRoom({
    required this.id,
    required this.kostId,
    required this.kostName,
    required this.ownerId,
    required this.ownerName,
    required this.seekerId,
    required this.seekerName,
    this.lastMessage,
    this.unreadCount = 0,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kostId': kostId,
    'kostName': kostName,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'seekerId': seekerId,
    'seekerName': seekerName,
    'lastMessage': lastMessage?.toJson(),
    'unreadCount': unreadCount,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
    id: json['id'] ?? '',
    kostId: json['kostId'] ?? '',
    kostName: json['kostName'] ?? '',
    ownerId: json['ownerId'] ?? '',
    ownerName: json['ownerName'] ?? '',
    seekerId: json['seekerId'] ?? '',
    seekerName: json['seekerName'] ?? '',
    lastMessage: json['lastMessage'] != null
        ? ChatMessage.fromJson(json['lastMessage'])
        : null,
    unreadCount: json['unreadCount'] ?? 0,
    messages: json['messages'] != null
        ? (json['messages'] as List)
              .map((m) => ChatMessage.fromJson(m))
              .toList()
        : [],
  );
}
