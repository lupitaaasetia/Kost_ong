// screens/kost_detail_screen.dart - FIXED with photo_view & carousel_slider
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// Using built-in PageView + InteractiveViewer instead of external packages
import '../models/kost.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'booking_screen.dart';

class KostDetailScreen extends StatefulWidget {
  final BaseKost kost;
  final int initialImageIndex;
  const KostDetailScreen({
    super.key,
    required this.kost,
    this.initialImageIndex = 0,
  });

  @override
  State<KostDetailScreen> createState() => _KostDetailScreenState();
}

class _KostDetailScreenState extends State<KostDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final BookingService _bookingService = BookingService();
  bool _isBookmarked = false;
  GoogleMapController? _mapController;
  List<Review> _reviews = [];
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _currentImageIndex = widget.initialImageIndex;
    _pageController = PageController(initialPage: widget.initialImageIndex);
    _isBookmarked = _bookingService.isFavorite(widget.kost.id);
    _loadReviews();
  }

  void _loadReviews() {
    setState(() {
      _reviews = _bookingService.getReviewsByKostId(widget.kost.id);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = widget.kost.phoneNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final message = Uri.encodeComponent(
      'Halo, saya tertarik dengan ${widget.kost.name}. Bisakah saya mendapat informasi lebih lanjut?',
    );
    final url = 'https://wa.me/62$phoneNumber?text=$message';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  LatLng get _kostLocation {
    return LatLng(widget.kost.latitude, widget.kost.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.kost.getPrimaryColor();
    final IconData kostIcon = widget.kost.getKostIcon();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar dengan Image Gallery menggunakan CarouselSlider
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image gallery menggunakan PageView
                  SizedBox(
                    height: 350,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.kost.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showFullscreenGallery(index),
                          child: Hero(
                            tag: 'kost_${widget.kost.id}_image_$index',
                            child: Image.network(
                              widget.kost.imageUrls[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        primaryColor.withOpacity(0.8),
                                        primaryColor.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      kostIcon,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          color: primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Image indicator dots
                  if (widget.kost.imageUrls.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.kost.imageUrls.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Tap to view hint
                  Positioned(
                    bottom: 45,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _showFullscreenGallery(_currentImageIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_out_map,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentImageIndex + 1}/${widget.kost.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(kostIcon, color: primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.kost.getKostType(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content sections
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 8),
                  _buildDescriptionSection(),
                  const SizedBox(height: 8),
                  _buildTypeSpecificSection(),
                  const SizedBox(height: 8),
                  _buildFacilitiesSection(),
                  const SizedBox(height: 8),
                  _buildMapSection(),
                  const SizedBox(height: 8),
                  _buildContactSection(),
                  const SizedBox(height: 8),
                  _buildReviewsSection(),
                  const SizedBox(height: 8),
                  _buildStatisticsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.kost.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[400], size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.kost.address,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.kost.getPrimaryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.kost.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' (${_reviews.length} review)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.kost.status == KostStatus.available
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.kost.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.kost.getFormattedPrice(),
                    style: TextStyle(
                      color: widget.kost.getPrimaryColor(),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Updated: ${_formatDate(widget.kost.updatedAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: widget.kost.getPrimaryColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Deskripsi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.kost.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificSection() {
    if (widget.kost is FemaleKost) {
      FemaleKost femaleKost = widget.kost as FemaleKost;
      return _buildInfoSection('Informasi Kost Perempuan', Icons.woman, [
        InfoItem('Jam Malam', femaleKost.curfewTime),
        InfoItem(
          'Security Guard',
          femaleKost.hasSecurityGuard ? 'Ada' : 'Tidak ada',
        ),
      ], Colors.pink);
    } else if (widget.kost is MaleKost) {
      MaleKost maleKost = widget.kost as MaleKost;
      return _buildInfoSection('Informasi Kost Laki-laki', Icons.man, [
        InfoItem(
          'Workspace',
          maleKost.hasWorkspace ? 'Tersedia' : 'Tidak tersedia',
        ),
        InfoItem(
          'Smoking Policy',
          maleKost.allowsSmoking ? 'Diperbolehkan' : 'Dilarang',
        ),
      ], Colors.blue);
    } else if (widget.kost is MixedKost) {
      MixedKost mixedKost = widget.kost as MixedKost;
      return _buildInfoSection('Informasi Kost Campur', Icons.people, [
        InfoItem('Kamar Pria', '${mixedKost.maleRooms} kamar'),
        InfoItem('Kamar Wanita', '${mixedKost.femaleRooms} kamar'),
        InfoItem('Total Kamar', '${mixedKost.totalRooms} kamar'),
        InfoItem(
          'Pintu Masuk',
          mixedKost.hasSeparateEntrance ? 'Terpisah' : 'Bersama',
        ),
      ], Colors.green);
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    List<InfoItem> items,
    Color color,
  ) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_repair_service,
                color: widget.kost.getPrimaryColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Fasilitas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.kost.facilities.length,
            itemBuilder: (context, index) {
              final facility = widget.kost.facilities[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: facility.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: facility.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(facility.icon, size: 16, color: facility.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        facility.name,
                        style: TextStyle(
                          color: facility.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: widget.kost.getPrimaryColor(), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Lokasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _kostLocation,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('kost_location'),
                    position: _kostLocation,
                    infoWindow: InfoWindow(
                      title: widget.kost.name,
                      snippet: widget.kost.address,
                    ),
                  ),
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final url =
                  'https://www.google.com/maps/search/?api=1&query=${_kostLocation.latitude},${_kostLocation.longitude}';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            icon: const Icon(Icons.directions),
            label: const Text('Buka di Google Maps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.kost.getPrimaryColor(),
              side: BorderSide(color: widget.kost.getPrimaryColor()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_phone,
                color: widget.kost.getPrimaryColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Kontak Pemilik',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchWhatsApp,
              icon: const Icon(Icons.chat, color: Colors.white),
              label: Text(
                'Chat via WhatsApp: ${widget.kost.phoneNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final phoneUrl = 'tel:${widget.kost.phoneNumber}';
                if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                  await launchUrl(Uri.parse(phoneUrl));
                }
              },
              icon: Icon(Icons.phone, color: widget.kost.getPrimaryColor()),
              label: Text(
                'Telepon: ${widget.kost.phoneNumber}',
                style: TextStyle(
                  color: widget.kost.getPrimaryColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.kost.getPrimaryColor()),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rate_review,
                    color: widget.kost.getPrimaryColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAddReviewDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tulis Review'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada review',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length > 3 ? 3 : _reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(_reviews[index]);
              },
            ),
          if (_reviews.length > 3)
            TextButton(
              onPressed: () => _showAllReviews(),
              child: Text('Lihat semua ${_reviews.length} review'),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.kost.getPrimaryColor(),
                  child: Text(
                    review.userName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
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
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: review.rating,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 16,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            if (review.pros.isNotEmpty || review.cons.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (review.pros.isNotEmpty) ...[
                const Text(
                  'Kelebihan:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: review.pros.map((pro) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pro,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (review.cons.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Kekurangan:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: review.cons.map((con) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        con,
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    double rating = 5.0;
    final commentController = TextEditingController();
    final List<String> pros = [];
    final List<String> cons = [];
    final prosController = TextEditingController();
    final consController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tulis Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating:'),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (value) {
                    setState(() => rating = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Komentar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: prosController,
                  decoration: InputDecoration(
                    labelText: 'Kelebihan',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (prosController.text.isNotEmpty) {
                          setState(() {
                            pros.add(prosController.text);
                            prosController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (pros.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: pros.map((pro) {
                      return Chip(
                        label: Text(pro),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => pros.remove(pro));
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: consController,
                  decoration: InputDecoration(
                    labelText: 'Kekurangan',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (consController.text.isNotEmpty) {
                          setState(() {
                            cons.add(consController.text);
                            consController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (cons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: cons.map((con) {
                      return Chip(
                        label: Text(con),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => cons.remove(con));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  _bookingService.addReview(
                    kostId: widget.kost.id,
                    userEmail: 'user@email.com',
                    userName: 'User',
                    rating: rating,
                    comment: commentController.text,
                    pros: pros,
                    cons: cons,
                  );
                  Navigator.pop(context);
                  _loadReviews();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review berhasil ditambahkan!'),
                    ),
                  );
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Semua Review (${_reviews.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  return _buildReviewCard(_reviews[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: widget.kost.getPrimaryColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Informasi Detail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Dibuat',
                  _formatDate(widget.kost.createdAt),
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Update',
                  _formatDate(widget.kost.updatedAt),
                  Icons.update,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isBookmarked = !_isBookmarked;
                  if (_isBookmarked) {
                    _bookingService.addFavorite(widget.kost.id);
                  } else {
                    _bookingService.removeFavorite(widget.kost.id);
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isBookmarked
                          ? 'Ditambahkan ke favorit!'
                          : 'Dihapus dari favorit!',
                    ),
                    backgroundColor: widget.kost.getPrimaryColor(),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              ),
              label: Text(_isBookmarked ? 'Tersimpan' : 'Simpan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.kost.getPrimaryColor(),
                side: BorderSide(color: widget.kost.getPrimaryColor()),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: widget.kost.status == KostStatus.available
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingScreen(kost: widget.kost),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.event_available, color: Colors.white),
              label: Text(
                widget.kost.status == KostStatus.available
                    ? 'Booking Sekarang'
                    : widget.kost.status.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.kost.status == KostStatus.available
                    ? widget.kost.getPrimaryColor()
                    : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // 🔥 Fullscreen Gallery dengan PhotoView - Zoom & Swipe
  void _showFullscreenGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenGalleryScreen(
          imageUrls: widget.kost.imageUrls,
          initialIndex: initialIndex,
          kostName: widget.kost.name,
          kostId: widget.kost.id,
        ),
      ),
    );
  }
}

// Helper class
class InfoItem {
  final String label;
  final String value;

  InfoItem(this.label, this.value);
}

// 🖼️ Fullscreen Gallery Screen dengan PhotoView
class FullscreenGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String kostName;
  final String? kostId; // used to build matching Hero tags

  const FullscreenGalleryScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.kostName,
    this.kostId,
  });

  @override
  State<FullscreenGalleryScreen> createState() =>
      _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState extends State<FullscreenGalleryScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen gallery: PageView + InteractiveViewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                    child: Hero(
                    tag: 'kost_${widget.kostId ?? widget.imageUrls.hashCode}_image_$index',
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.white54,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top Bar - Close & Title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.kostName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pinch untuk zoom • Geser untuk foto lain',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur share dalam pengembangan'),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar - Image Counter & Indicators
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentIndex + 1} / ${widget.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dot Indicators
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
