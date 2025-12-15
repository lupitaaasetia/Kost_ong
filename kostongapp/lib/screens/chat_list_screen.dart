import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Tambahkan import async
import '../services/api_service.dart';
import '../models/chat_model.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _chatRooms = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    // ✅ FITUR BARU: Auto-refresh daftar chat setiap 5 detik
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) _loadChatRooms(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChatRooms({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final result = await ApiService.fetchChatRooms(token);
    
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _chatRooms = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (showLoading) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadChatRooms(),
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text('Belum ada percakapan', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final roomData = _chatRooms[index];
                    
                    // Tentukan apakah user saat ini adalah pencari atau pemilik dalam konteks chat ini
                    // Logika sederhana: Jika ID saya ada di 'sender_id' pesan terakhir, maka saya pengirim.
                    // Tapi lebih baik kita lihat 'other_user_id' yang dikirim backend.
                    
                    final otherUserId = roomData['other_user_id'];
                    final otherUserName = roomData['other_user_name'] ?? 'Unknown';
                    final kostName = roomData['kost_name'] ?? 'Kost';
                    
                    // Konstruksi ChatRoom object untuk navigasi
                    final chatRoom = ChatRoom(
                      kostId: roomData['kost_id'],
                      kostName: kostName,
                      // Kita set owner/seeker secara dinamis agar kompatibel dengan ChatDetailScreen
                      // Asumsi: Jika saya Admin, maka 'other' adalah Seeker.
                      // Tapi ChatDetailScreen butuh ID spesifik.
                      // Trik: Kita kirim ID lawan bicara sebagai salah satu ID, dan ID kita sebagai ID lainnya.
                      // Nanti di ChatDetailScreen akan dicek lagi.
                      ownerId: widget.currentUserId, 
                      ownerName: widget.currentUserName,
                      seekerId: otherUserId,
                      seekerName: otherUserName,
                      
                      lastMessage: ChatMessage(
                        id: 'last',
                        message: roomData['last_message'] ?? '...',
                        senderId: roomData['sender_id'] ?? '',
                        timestamp: DateTime.tryParse(roomData['created_at'] ?? '') ?? DateTime.now(),
                      ),
                    );

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                            style: TextStyle(color: Theme.of(context).primaryColor),
                          ),
                        ),
                        title: Text(otherUserName, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kostName, style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              roomData['last_message'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chatRoom: chatRoom,
                                currentUserId: widget.currentUserId,
                                currentUserName: widget.currentUserName,
                              ),
                            ),
                          );
                          _loadChatRooms(showLoading: false);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
