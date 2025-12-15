import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ReviewScreen extends StatefulWidget {
  final String kostId;
  const ReviewScreen({Key? key, required this.kostId}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late Future<List<dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  Future<List<dynamic>> _loadReviews() async {
    final result = await ApiService.fetchReviews(widget.kostId);
    if (result['success'] == true) {
      return result['data'];
    }
    return [];
  }

  Future<void> _postReview(double rating, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk memberi ulasan')),
      );
      return;
    }

    final data = {
      'kost_id': widget.kostId,
      'rating': rating,
      'content': content,
    };

    final result = await ApiService.createReview(token, data);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan berhasil dikirim'), backgroundColor: Colors.green),
      );
      setState(() {
        _reviewsFuture = _loadReviews(); // Refresh list
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mengirim ulasan'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ulasan Penghuni'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada ulasan.'));
          }
          final reviews = snapshot.data!;
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(reviews[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReviewDialog(),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final userName = review['user_id']?['nama_lengkap'] ?? 'Anonim';
    final rating = (review['rating'] as num).toDouble();
    final date = DateTime.parse(review['created_at']);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(userName.isNotEmpty ? userName[0] : 'A'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(review['content']),
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    double _rating = 5.0;
    final _contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tulis Ulasan Anda'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rating: ${_rating.toStringAsFixed(1)}'),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.toString(),
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(hintText: 'Tulis ulasan Anda di sini...'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_contentController.text.isNotEmpty) {
                      _postReview(_rating, _contentController.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
