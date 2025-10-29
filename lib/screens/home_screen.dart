// screens/home_screen.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kost.dart';
import '../services/kost_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import 'kost_detail_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'owner_profil_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  final bool isOwner;

  const HomeScreen({super.key, required this.userEmail, this.isOwner = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Private widget: swipeable image carousel for kost card
class _KostImageCarousel extends StatefulWidget {
  final BaseKost kost;

  const _KostImageCarousel({Key? key, required this.kost}) : super(key: key);

  @override
  State<_KostImageCarousel> createState() => _KostImageCarouselState();
}

class _KostImageCarouselState extends State<_KostImageCarousel> {
  late final PageController _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kost = widget.kost;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: kost.imageUrls.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KostDetailScreen(
                            kost: kost,
                            initialImageIndex: _current,
                          ),
                        ),
                      );
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemCount: kost.imageUrls.length,
                      itemBuilder: (context, index) {
                        final url = kost.imageUrls[index];
                        return Hero(
                          tag: 'kost_${kost.id}_image_$index',
                          child: Image.network(
                            url,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: kost.getPrimaryColor().withOpacity(
                                    0.3,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      kost.getKostIcon(),
                                      size: 60,
                                      color: kost.getPrimaryColor(),
                                    ),
                                  ),
                                ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                        : null,
                                    color: kost.getPrimaryColor(),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    color: kost.getPrimaryColor().withOpacity(0.3),
                    child: Center(
                      child: Icon(
                        kost.getKostIcon(),
                        size: 60,
                        color: kost.getPrimaryColor(),
                      ),
                    ),
                  ),
          ),
          // gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
          // indicators
          if (kost.imageUrls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  kost.imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _current == i ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final KostService _kostService = KostService();
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();

  List<BaseKost> _filteredKostList = [];
  List<BaseKost> _allKostList = [];
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  bool _showScrollToTop = false;

  final List<String> _filterOptions = [
    'Semua',
    'Harga Termurah',
    'Rating Tertinggi',
    'Kost Perempuan',
    'Kost Laki-laki',
    'Kost Campur',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _initializeData() {
    _kostService.initializeData();
    _allKostList = _kostService.allKost;
    _filteredKostList = List.from(_allKostList);
    _bookingService.initializeDemoReviews(_allKostList);
    _notificationService.initialize(widget.userEmail);
    setState(() {});
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<BaseKost> results = _kostService.advancedSearch(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      kostType: _selectedFilter == 'Semua'
          ? null
          : _getKostTypeFromFilter(_selectedFilter),
      sortBy: SortCriteria.name,
      ascending: true,
    );

    if (_selectedFilter == 'Harga Termurah') {
      results = _kostService.sortKost(
        results,
        SortCriteria.price,
        ascending: true,
      );
    } else if (_selectedFilter == 'Rating Tertinggi') {
      results = _kostService.sortKost(
        results,
        SortCriteria.rating,
        ascending: false,
      );
    }

    setState(() => _filteredKostList = results);
  }

  String? _getKostTypeFromFilter(String filter) {
    switch (filter) {
      case 'Kost Perempuan':
        return 'Kost Perempuan';
      case 'Kost Laki-laki':
        return 'Kost Laki-laki';
      case 'Kost Campur':
        return 'Kost Campur';
      default:
        return null;
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchSection()),
          SliverToBoxAdapter(child: _buildFilterSection()),
          SliverToBoxAdapter(child: _buildResultCount()),
          _filteredKostList.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildKostCard(_filteredKostList[index]),
                      ),
                      childCount: _filteredKostList.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: const Color(0xFF6B46C1),
              mini: true,
              child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    final unreadCount = _notificationService.getUnreadCount(widget.userEmail);

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF6B46C1),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'KostQu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Center welcome text and show user email in a pill-shaped box
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Selamat Datang!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.userEmail,
                            style: const TextStyle(
                              color: Color(0xFF6B46C1),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Notification Bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationsScreen(userEmail: widget.userEmail),
                  ),
                ).then((_) => setState(() {})); // Refresh after back
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // Profile Icon
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => widget.isOwner
                      ? OwnerProfileScreen(userEmail: widget.userEmail)
                      : ProfileScreen(userEmail: widget.userEmail),
                ),
              );

              // If owner added a kost and returned true, refresh the list
              if (result == true) {
                _initializeData();
              }
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Text(
                widget.userEmail[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF6B46C1),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // BottomNavigationBar is defined in the main scaffold (if used).
  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari kost, alamat, atau fasilitas...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6B46C1)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF6B46C1), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = _selectedFilter == option;
                return GestureDetector(
                  onTap: () => _onFilterSelected(option),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6B46C1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCount() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
          const SizedBox(width: 4),
          Text(
            'Ditemukan ${_filteredKostList.length} kost tersedia',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada kost ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilter = 'Semua';
                _searchController.clear();
                _applyFilters();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B46C1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKostCard(BaseKost kost) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                KostDetailScreen(kost: kost, initialImageIndex: 0),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE CAROUSEL (swipeable)
            _KostImageCarousel(kost: kost),
            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kost.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          kost.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kost.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: kost.facilities.take(3).map((facility) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: facility.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: facility.color.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              facility.icon,
                              size: 12,
                              color: facility.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              facility.name,
                              style: TextStyle(
                                color: facility.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  if (kost.facilities.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+${kost.facilities.length - 3} fasilitas lainnya',
                        style: TextStyle(
                          color: kost.getPrimaryColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kost.getFormattedPrice(),
                            style: TextStyle(
                              color: kost.getPrimaryColor(),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Update: ${_formatDate(kost.updatedAt)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KostDetailScreen(
                              kost: kost,
                              initialImageIndex: 0,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kost.getPrimaryColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
