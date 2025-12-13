import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ManageReviewsScreen extends StatefulWidget {
  final String token;

  const ManageReviewsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ManageReviewsScreen> createState() => _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends State<ManageReviewsScreen> {
  bool _loading = true;
  List<dynamic> _allReviews = [];
  List<dynamic> _filteredReviews = [];
  int? _selectedRating;
  String _sortBy = 'Terbaru';

  final List<String> _sortOptions = [
    'Terbaru',
    'Terlama',
    'Rating Tertinggi',
    'Rating Terendah',
  ];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);

    final result = await ApiService.fetchReview(widget.token);

    if (result['success'] == true) {
      setState(() {
        _allReviews = result['data'] ?? [];
        _filterAndSortReviews();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _showSnackBar(result['message'] ?? 'Gagal memuat review', isError: true);
    }
  }

  void _filterAndSortReviews() {
    // Filter by rating
    _filteredReviews = _selectedRating == null
        ? List.from(_allReviews)
        : _allReviews.where((r) {
            final rating = r['rating'];
            if (rating is int) {
              return rating == _selectedRating;
            } else if (rating is double) {
              return rating.toInt() == _selectedRating;
            } else if (rating is String) {
              return int.tryParse(rating) == _selectedRating;
            }
            return false;
          }).toList();

    // Sort
    switch (_sortBy) {
      case 'Terbaru':
        _filteredReviews.sort(
          (a, b) => (b['created_at']?.toString() ?? '').compareTo(
            a['created_at']?.toString() ?? '',
          ),
        );
        break;
      case 'Terlama':
        _filteredReviews.sort(
          (a, b) => (a['created_at']?.toString() ?? '').compareTo(
            b['created_at']?.toString() ?? '',
          ),
        );
        break;
      case 'Rating Tertinggi':
        _filteredReviews.sort((a, b) {
          final ratingA = _getRatingValue(a['rating']);
          final ratingB = _getRatingValue(b['rating']);
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Rating Terendah':
        _filteredReviews.sort((a, b) {
          final ratingA = _getRatingValue(a['rating']);
          final ratingB = _getRatingValue(b['rating']);
          return ratingA.compareTo(ratingB);
        });
        break;
    }
  }

  int _getRatingValue(dynamic rating) {
    if (rating is int) return rating;
    if (rating is double) return rating.toInt();
    if (rating is String) return int.tryParse(rating) ?? 0;
    return 0;
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Review'),
        content: Text('Yakin ingin menghapus review ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteReview(widget.token, reviewId);

      if (result['success'] == true) {
        _showSnackBar('Review berhasil dihapus');
        _loadReviews();
      } else {
        _showSnackBar(
          result['message'] ?? 'Gagal menghapus review',
          isError: true,
        );
      }
    }
  }

  void _replyToReview(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        review: review,
        token: widget.token,
        onSuccess: () {
          Navigator.pop(context);
          _showSnackBar('Balasan berhasil dikirim');
          _loadReviews();
        },
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _calculateAverageRating() {
    if (_allReviews.isEmpty) return 0.0;
    final sum = _allReviews.fold<double>(
      0.0,
      (sum, review) => sum + _getRatingValue(review['rating']).toDouble(),
    );
    return sum / _allReviews.length;
  }

  Map<int, int> _getRatingDistribution() {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var review in _allReviews) {
      final rating = _getRatingValue(review['rating']);
      if (rating >= 1 && rating <= 5) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = _calculateAverageRating();
    final ratingDistribution = _getRatingDistribution();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Kelola Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF667eea),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _filterAndSortReviews();
              });
            },
            itemBuilder: (context) => _sortOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (_sortBy == option)
                      Icon(Icons.check, size: 18, color: Color(0xFF667eea))
                    else
                      SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: Column(
                children: [
                  _buildSummaryCard(avgRating, ratingDistribution),
                  _buildRatingFilter(),
                  Expanded(
                    child: _filteredReviews.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _filteredReviews.length,
                            itemBuilder: (context, index) {
                              final review = _filteredReviews[index];
                              return _buildReviewCard(review);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(double avgRating, Map<int, int> distribution) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStarRating(avgRating.round(), size: 20),
                    SizedBox(height: 8),
                    Text(
                      '${_allReviews.length} Review',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = distribution[rating] ?? 0;
                    final percentage = _allReviews.isEmpty
                        ? 0.0
                        : (count / _allReviews.length) * 100;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$rating',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.star, color: Colors.amber, size: 12),
                          SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Semua', null),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            return _buildFilterChip('$rating ⭐', rating);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? rating) {
    final isSelected = _selectedRating == rating;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRating = rating;
            _filterAndSortReviews();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Color(0xFF667eea).withOpacity(0.2),
        checkmarkColor: Color(0xFF667eea),
        labelStyle: TextStyle(
          color: isSelected ? Color(0xFF667eea) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 100, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Belum ada review',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = _getRatingValue(review['rating']);
    final hasReply =
        review['reply'] != null &&
        review['reply'].toString().isNotEmpty &&
        review['reply'].toString() != 'null';

    // Format date
    String formattedDate = '-';
    try {
      if (review['created_at'] != null) {
        final date = DateTime.parse(review['created_at'].toString());
        formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);
      }
    } catch (e) {
      formattedDate = review['created_at']?.toString() ?? '-';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF667eea).withOpacity(0.1),
                  child: Text(
                    (review['nama_reviewer']?.toString() ?? 'A')[0]
                        .toUpperCase(),
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['nama_reviewer']?.toString() ?? 'Anonymous',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStarRating(rating, size: 14),
                          SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    if (!hasReply)
                      PopupMenuItem(
                        value: 'reply',
                        child: Row(
                          children: [
                            Icon(Icons.reply, size: 18),
                            SizedBox(width: 8),
                            Text('Balas'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'reply') {
                      _replyToReview(review);
                    } else if (value == 'delete') {
                      _deleteReview(review['id'].toString());
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              review['komentar']?.toString() ?? '',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            if (hasReply) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF667eea).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF667eea).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Color(0xFF667eea)),
                        SizedBox(width: 6),
                        Text(
                          'Balasan Anda',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      review['reply'].toString(),
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _replyToReview(review),
                icon: Icon(Icons.reply, size: 18),
                label: Text('Balas Review'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF667eea),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}

class ReplyDialog extends StatefulWidget {
  final Map<String, dynamic> review;
  final String token;
  final VoidCallback onSuccess;

  const ReplyDialog({
    Key? key,
    required this.review,
    required this.token,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Balasan tidak boleh kosong'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.replyToReview(
      widget.token,
      widget.review['id'].toString(),
      _controller.text,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim balasan'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Balas Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.review['komentar']?.toString() ?? '',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Tulis balasan Anda...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 4,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF667eea),
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Kirim'),
        ),
      ],
    );
  }
}
