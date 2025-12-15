// screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import '../services/chat_services.dart';
import 'chat_detail_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ChatListScreen({Key? key, required this.userId, required this.userName})
    : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> _chatRooms = [];


  > kostong-backend@1.0.0 start
  > node server.js

  Server running on port 3000
  MongoDB connected
  ❌ VALIDASI GAGAL! Detail:
  {
  "operatorName": "$jsonSchema",
  "schemaRulesNotSatisfied": [
  {
  "operatorName": "required",
  "specifiedAs": {
  "required": [
  "_id",
  "biaya_admin",
  "catatan",
  "created_at",
  "durasi",
  "expired_at",
  "harga_total",
  "kamar_id",
  "kost_id",
  "metode_pembayaran",
  "nomor_booking",
  "status_booking",
  "tanggal_mulai",
  "tanggal_selesai",
  "tipe_durasi",
  "total_bayar",
  "updated_at",
  "user_id"
  ]
  },
  "missingProperties": [
  "biaya_admin",
  "created_at",
  "durasi",
  "expired_at",
  "harga_total",
  "kamar_id",
  "nomor_booking",
  "status_booking",
  "tanggal_mulai",
  "tanggal_selesai",
  "tipe_durasi",
  "total_bayar",
  "updated_at"
  ]
  }
  ]
  }

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  void _loadChatRooms() {
    setState(() {
      _chatRooms = ChatService.getChatRoomsForUser(widget.userId);
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'id_ID').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pesan'),
        backgroundColor: const Color(0xFF4facfe),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chatRooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum ada percakapan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai chat dengan pemilik kost',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadChatRooms();
              },
              color: const Color(0xFF4facfe),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _chatRooms.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, indent: 88, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final room = _chatRooms[index];
                  final isOwner = room.ownerId == widget.userId;
                  final otherName = isOwner ? room.seekerName : room.ownerName;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF4facfe),
                          child: Text(
                            otherName.isNotEmpty
                                ? otherName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (room.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  room.unreadCount > 9
                                      ? '9+'
                                      : room.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: TextStyle(
                              fontWeight: room.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (room.lastMessage != null)
                          Text(
                            _formatTimestamp(room.lastMessage!.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: room.unreadCount > 0
                                  ? const Color(0xFF4facfe)
                                  : Colors.grey[600],
                              fontWeight: room.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          room.kostName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (room.lastMessage != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (room.lastMessage!.senderId == widget.userId)
                                Icon(
                                  room.lastMessage!.isRead
                                      ? Icons.done_all
                                      : Icons.done,
                                  size: 16,
                                  color: room.lastMessage!.isRead
                                      ? const Color(0xFF4facfe)
                                      : Colors.grey[600],
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  room.lastMessage!.imageUrl != null
                                      ? '📷 Foto'
                                      : room.lastMessage!.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: room.unreadCount > 0
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontWeight: room.unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatRoom: room,
                            currentUserId: widget.userId,
                            currentUserName: widget.userName,
                          ),
                        ),
                      );
                      _loadChatRooms();
                    },
                  );
                },
              ),
            ),
    );
  }
}
