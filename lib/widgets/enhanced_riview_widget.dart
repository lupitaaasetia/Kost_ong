// widgets/enhanced_review_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/review_enhanced.dart';

class EnhancedReviewWidget extends StatelessWidget {
  final EnhancedReview review;
  final String currentUserId;
  final Function(String reviewId) onHelpfulTap;
  final Function(EnhancedReview review)? onReviewTap;
  final Color primaryColor;

  const EnhancedReviewWidget({
    super.key,
    required this.review,
    required this.currentUserId,
    required this.onHelpfulTap,
    this.onReviewTap,
    this.primaryColor = const Color(0xFF6B46C1),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onReviewTap?.call(review),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info header
              _buildUserHeader(),

              const SizedBox(height: 12),

              // Overall rating
              _buildOverallRating(),

              const SizedBox(height: 12),

              // Category ratings
              _buildCategoryRatings(),

              const SizedBox(height: 12),

              // Comment
              Text(
                review.comment,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                  fontSize: 14,
                ),
              ),

              // Photos
              if (review.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPhotoGallery(context),
              ],

              // Pros & Cons
              if (review.pros.isNotEmpty || review.cons.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildProsAndCons(),
              ],

              const SizedBox(height: 12),

              // Footer with helpful button
              _buildFooter(),

              // Owner response
              if (review.ownerResponse != null) ...[
                const SizedBox(height: 12),
                _buildOwnerResponse(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: review.userAvatarUrl != null
              ? NetworkImage(review.userAvatarUrl!)
              : null,
          child: review.userAvatarUrl == null
              ? Text(
                  review.userName[0].toUpperCase(),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),

        const SizedBox(width: 12),

        // Name and badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (review.isVerified) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Pernah menginap di kost ini',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (review.isUNESAStudent) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Mahasiswa UNESA',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'UNESA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    review.getFormattedDate(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (review.stayDuration != null) ...[
                    Text(
                      ' • ${review.stayDuration}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallRating() {
    return Row(
      children: [
        RatingBarIndicator(
          rating: review.ratings.overall,
          itemBuilder: (context, index) =>
              const Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: 20,
        ),
        const SizedBox(width: 8),
        Text(
          review.ratings.overall.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCategoryRatings() {
    return Column(
      children: [
        _buildCategoryRatingBar(
          'Kebersihan',
          review.ratings.cleanliness,
          Icons.cleaning_services,
        ),
        const SizedBox(height: 6),
        _buildCategoryRatingBar(
          'Keamanan',
          review.ratings.security,
          Icons.security,
        ),
        const SizedBox(height: 6),
        _buildCategoryRatingBar(
          'Fasilitas',
          review.ratings.facilities,
          Icons.home_repair_service,
        ),
        const SizedBox(height: 6),
        _buildCategoryRatingBar(
          'Responsif',
          review.ratings.ownerResponsiveness,
          Icons.support_agent,
        ),
        const SizedBox(height: 6),
        _buildCategoryRatingBar(
          'Harga Sesuai',
          review.ratings.valueForMoney,
          Icons.attach_money,
        ),
      ],
    );
  }

  Widget _buildCategoryRatingBar(String label, double rating, IconData icon) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rating / 5,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getRatingColor(rating),
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPhotoGallery(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: review.photoUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showPhotoGallery(context, index),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(review.photoUrls[index]),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}/${review.photoUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPhotoGallery(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${initialIndex + 1}/${review.photoUrls.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: _ReviewPhotoGallery(
                photoUrls: review.photoUrls,
                initialIndex: initialIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProsAndCons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (review.pros.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.thumb_up, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: review.pros.map((pro) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        pro,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
        if (review.pros.isNotEmpty && review.cons.isNotEmpty)
          const SizedBox(height: 8),
        if (review.cons.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.thumb_down, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: review.cons.map((con) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        con,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    final isHelpful = review.isHelpfulBy(currentUserId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Helpful button
        InkWell(
          onTap: () => onHelpfulTap(review.id),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHelpful
                  ? primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHelpful ? primaryColor : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 16,
                  color: isHelpful ? primaryColor : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Helpful',
                  style: TextStyle(
                    fontSize: 12,
                    color: isHelpful ? primaryColor : Colors.grey[700],
                    fontWeight: isHelpful ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (review.helpfulCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${review.helpfulCount})',
                    style: TextStyle(
                      fontSize: 11,
                      color: isHelpful ? primaryColor : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Report button
        TextButton.icon(
          onPressed: () {
            // Handle report
          },
          icon: Icon(Icons.flag_outlined, size: 14, color: Colors.grey[600]),
          label: Text(
            'Laporkan',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerResponse() {
    final response = review.ownerResponse!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.business,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.ownerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Pemilik Kost',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                _formatResponseDate(response.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            response.response,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatResponseDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}

// Small gallery widget used by review dialog to show photos with arrows + zoom
// Top-level so it can be reused from the stateless widget above.
class _ReviewPhotoGallery extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _ReviewPhotoGallery({
    Key? key,
    required this.photoUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<_ReviewPhotoGallery> createState() => _ReviewPhotoGalleryState();
}

class _ReviewPhotoGalleryState extends State<_ReviewPhotoGallery> {
  late PageController _controller;
  late int _current;
  final TransformationController _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _controller,
          // allow swipe between images, but only pan when zoomed
          onPageChanged: (i) {
            setState(() => _current = i);
            _transform.value = Matrix4.identity();
          },
          itemCount: widget.photoUrls.length,
          itemBuilder: (context, index) {
            return Center(
              child: InteractiveViewer(
                transformationController: _transform,
                panEnabled: _transform.value.getMaxScaleOnAxis() > 1.0,
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  widget.photoUrls[index],
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _current > 0
                ? () {
                    setState(() => _current--);
                    _controller.animateToPage(
                      _current,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
        ),
        Positioned(
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: _current < widget.photoUrls.length - 1
                ? () {
                    setState(() => _current++);
                    _controller.animateToPage(
                      _current,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

// Widget untuk menampilkan statistik review
class ReviewStatisticsWidget extends StatelessWidget {
  final ReviewStatistics statistics;
  final Color primaryColor;

  const ReviewStatisticsWidget({
    super.key,
    required this.statistics,
    this.primaryColor = const Color(0xFF6B46C1),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Overall score
                Column(
                  children: [
                    Text(
                      statistics.averageOverall.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: statistics.averageOverall,
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${statistics.totalReviews} review',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(width: 24),

                // Rating distribution
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      int stars = 5 - index;
                      return _buildRatingBar(stars, statistics);
                    }),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Category averages
            _buildCategoryAverage(
              'Kebersihan',
              statistics.averageCategories.cleanliness,
              Icons.cleaning_services,
            ),
            const SizedBox(height: 8),
            _buildCategoryAverage(
              'Keamanan',
              statistics.averageCategories.security,
              Icons.security,
            ),
            const SizedBox(height: 8),
            _buildCategoryAverage(
              'Fasilitas',
              statistics.averageCategories.facilities,
              Icons.home_repair_service,
            ),
            const SizedBox(height: 8),
            _buildCategoryAverage(
              'Responsif',
              statistics.averageCategories.ownerResponsiveness,
              Icons.support_agent,
            ),
            const SizedBox(height: 8),
            _buildCategoryAverage(
              'Harga Sesuai',
              statistics.averageCategories.valueForMoney,
              Icons.attach_money,
            ),

            const Divider(height: 24),

            // Additional stats
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  Icons.verified,
                  '${statistics.verifiedReviewsCount} Verified',
                  Colors.blue,
                ),
                _buildStatChip(
                  Icons.school,
                  '${statistics.unesaReviewsCount} UNESA',
                  Colors.green,
                ),
                _buildStatChip(
                  Icons.photo_camera,
                  '${statistics.reviewsWithPhotos} Foto',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, ReviewStatistics stats) {
    final count = stats.ratingDistribution[stars] ?? 0;
    final percentage = stats.getPercentageForRating(stars);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAverage(String label, double rating, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) =>
              const Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: 14,
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
