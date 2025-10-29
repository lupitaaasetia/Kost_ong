// widgets/advanced_filter_sheet.dart
import 'package:flutter/material.dart';
import '../models/facility.dart';

class KostFilter {
  double minPrice;
  double maxPrice;
  double? maxDistance; // in km
  Set<FacilityType> facilities;
  bool unesaDiscountOnly;
  double minRating;
  KostType? kostType;
  SortOption sortBy;
  bool ascending;

  KostFilter({
    this.minPrice = 500000,
    this.maxPrice = 2000000,
    this.maxDistance,
    Set<FacilityType>? facilities,
    this.unesaDiscountOnly = false,
    this.minRating = 0.0,
    this.kostType,
    this.sortBy = SortOption.newest,
    this.ascending = true,
  }) : facilities = facilities ?? {};

  bool get hasActiveFilters {
    return minPrice > 500000 ||
        maxPrice < 2000000 ||
        maxDistance != null ||
        facilities.isNotEmpty ||
        unesaDiscountOnly ||
        minRating > 0 ||
        kostType != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (minPrice > 500000 || maxPrice < 2000000) count++;
    if (maxDistance != null) count++;
    if (facilities.isNotEmpty) count++;
    if (unesaDiscountOnly) count++;
    if (minRating > 0) count++;
    if (kostType != null) count++;
    return count;
  }

  void reset() {
    minPrice = 500000;
    maxPrice = 2000000;
    maxDistance = null;
    facilities.clear();
    unesaDiscountOnly = false;
    minRating = 0.0;
    kostType = null;
    sortBy = SortOption.newest;
    ascending = true;
  }
}

enum KostType { male, female, mixed }

enum SortOption { price, distance, rating, newest, name }

class AdvancedFilterSheet extends StatefulWidget {
  final KostFilter initialFilter;
  final Function(KostFilter) onApply;

  const AdvancedFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late KostFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = KostFilter(
      minPrice: widget.initialFilter.minPrice,
      maxPrice: widget.initialFilter.maxPrice,
      maxDistance: widget.initialFilter.maxDistance,
      facilities: Set.from(widget.initialFilter.facilities),
      unesaDiscountOnly: widget.initialFilter.unesaDiscountOnly,
      minRating: widget.initialFilter.minRating,
      kostType: widget.initialFilter.kostType,
      sortBy: widget.initialFilter.sortBy,
      ascending: widget.initialFilter.ascending,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: Color(0xFF6B46C1)),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter & Urutkan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_filter.hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_filter.activeFilterCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _filter.reset());
                      },
                      child: const Text('Reset'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Price Range
                _buildSectionTitle('Rentang Harga'),
                const SizedBox(height: 8),
                Text(
                  'Rp ${(_filter.minPrice / 1000).toStringAsFixed(0)}rb - Rp ${(_filter.maxPrice / 1000).toStringAsFixed(0)}rb',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B46C1),
                  ),
                ),
                RangeSlider(
                  values: RangeValues(_filter.minPrice, _filter.maxPrice),
                  min: 500000,
                  max: 2000000,
                  divisions: 15,
                  activeColor: const Color(0xFF6B46C1),
                  labels: RangeLabels(
                    'Rp ${(_filter.minPrice / 1000).toStringAsFixed(0)}rb',
                    'Rp ${(_filter.maxPrice / 1000).toStringAsFixed(0)}rb',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _filter.minPrice = values.start;
                      _filter.maxPrice = values.end;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Distance
                _buildSectionTitle('Jarak dari Kampus'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDistanceChip('Semua', null)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDistanceChip('< 1 km', 1.0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDistanceChip('< 3 km', 3.0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDistanceChip('< 5 km', 5.0)),
                  ],
                ),

                const SizedBox(height: 24),

                // Kost Type
                _buildSectionTitle('Tipe Kost'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildKostTypeChip('Semua', null, Icons.home),
                    _buildKostTypeChip('Putra', KostType.male, Icons.man),
                    _buildKostTypeChip('Putri', KostType.female, Icons.woman),
                    _buildKostTypeChip('Campur', KostType.mixed, Icons.people),
                  ],
                ),

                const SizedBox(height: 24),

                // Facilities
                _buildSectionTitle('Fasilitas'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FacilityType.values.map((type) {
                    return _buildFacilityChip(type);
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Rating
                _buildSectionTitle('Rating Minimal'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildRatingChip(0, 'Semua')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRatingChip(3, '3+')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRatingChip(4, '4+')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRatingChip(4.5, '4.5+')),
                  ],
                ),

                const SizedBox(height: 24),

                // UNESA Discount
                SwitchListTile(
                  value: _filter.unesaDiscountOnly,
                  onChanged: (value) {
                    setState(() => _filter.unesaDiscountOnly = value);
                  },
                  title: const Row(
                    children: [
                      Icon(Icons.school, color: Color(0xFF6B46C1), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hanya Diskon UNESA',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Tampilkan kost dengan diskon mahasiswa',
                  ),
                  activeThumbColor: const Color(0xFF6B46C1),
                ),

                const SizedBox(height: 24),

                // Sort Options
                _buildSectionTitle('Urutkan Berdasarkan'),
                const SizedBox(height: 12),
                _buildSortOption(SortOption.newest, 'Terbaru', Icons.fiber_new),
                _buildSortOption(SortOption.price, 'Harga', Icons.attach_money),
                _buildSortOption(
                  SortOption.distance,
                  'Jarak',
                  Icons.location_on,
                ),
                _buildSortOption(SortOption.rating, 'Rating', Icons.star),
                _buildSortOption(SortOption.name, 'Nama', Icons.sort_by_alpha),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Apply Button
          Container(
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
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_filter);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Terapkan Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDistanceChip(String label, double? distance) {
    final isSelected = _filter.maxDistance == distance;
    return InkWell(
      onTap: () => setState(() => _filter.maxDistance = distance),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildKostTypeChip(String label, KostType? type, IconData icon) {
    final isSelected = _filter.kostType == type;
    return InkWell(
      onTap: () => setState(() => _filter.kostType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityChip(FacilityType type) {
    final isSelected = _filter.facilities.contains(type);
    final iconData = _getFacilityIcon(type);
    final label = _getFacilityLabel(type);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _filter.facilities.remove(type);
          } else {
            _filter.facilities.add(type);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 14,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingChip(double rating, String label) {
    final isSelected = _filter.minRating == rating;
    return InkWell(
      onTap: () => setState(() => _filter.minRating = rating),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: isSelected ? Colors.white : Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(SortOption option, String label, IconData icon) {
    final isSelected = _filter.sortBy == option;
    return InkWell(
      onTap: () {
        setState(() {
          if (_filter.sortBy == option) {
            _filter.ascending = !_filter.ascending;
          } else {
            _filter.sortBy = option;
            _filter.ascending = true;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B46C1).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6B46C1) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6B46C1) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                _filter.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                color: const Color(0xFF6B46C1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFacilityIcon(FacilityType type) {
    switch (type) {
      case FacilityType.bathroom:
        return Icons.bathroom;
      case FacilityType.cooling:
        return Icons.ac_unit;
      case FacilityType.electrical:
        return Icons.electrical_services;
      case FacilityType.internet:
        return Icons.wifi;
      case FacilityType.parking:
        return Icons.local_parking;
      case FacilityType.kitchen:
        return Icons.kitchen;
      case FacilityType.security:
        return Icons.security;
      case FacilityType.other:
        return Icons.more_horiz;
      case FacilityType.general:
        return Icons.check_circle_outline;
      case FacilityType.room:
        return Icons.bed;
      case FacilityType.service:
        return Icons.room_service;
    }
  }

  String _getFacilityLabel(FacilityType type) {
    switch (type) {
      case FacilityType.bathroom:
        return 'K. Mandi';
      case FacilityType.cooling:
        return 'AC';
      case FacilityType.electrical:
        return 'Listrik';
      case FacilityType.internet:
        return 'WiFi';
      case FacilityType.parking:
        return 'Parkir';
      case FacilityType.kitchen:
        return 'Dapur';
      case FacilityType.security:
        return 'Security';
      case FacilityType.other:
        return 'Lainnya';
      case FacilityType.general:
        return 'Umum';
      case FacilityType.room:
        return 'Kamar';
      case FacilityType.service:
        return 'Layanan';
    }
  }
}
