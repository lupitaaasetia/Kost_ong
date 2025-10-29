// screens/map_view_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/kost.dart';
// kost_service removed from this screen because data is passed in via constructor
import 'kost_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  final List<BaseKost> kosts;

  const MapViewScreen({super.key, required this.kosts});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  // KostService removed: data supplied via widget.kosts

  // Default to UNESA Kampus 5 Magetan location
  final LatLng _unesaLocation = const LatLng(-7.6464, 111.3468);
  Position? _currentPosition;
  Set<Marker> _markers = {};
  BaseKost? _selectedKost;
  bool _isLoadingLocation = true;

  // Map types
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _createMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Add user location marker
      _addUserLocationMarker();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _addUserLocationMarker() {
    if (_currentPosition == null) return;

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Lokasi Anda'),
    );

    setState(() {
      _markers.add(userMarker);
    });
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    for (var kost in widget.kosts) {
      markers.add(
        Marker(
          markerId: MarkerId(kost.id),
          position: LatLng(kost.latitude, kost.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(kost)),
          infoWindow: InfoWindow(
            title: kost.name,
            snippet: kost.getFormattedPrice(),
            onTap: () => _onMarkerTapped(kost),
          ),
          onTap: () => _onMarkerTapped(kost),
        ),
      );
    }

    // Add UNESA marker
    markers.add(
      Marker(
        markerId: const MarkerId('unesa_kampus'),
        position: _unesaLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'UNESA Kampus 5 Magetan',
          snippet: 'Kampus',
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  double _getMarkerColor(BaseKost kost) {
    if (kost is FemaleKost) return BitmapDescriptor.hueRose;
    if (kost is MaleKost) return BitmapDescriptor.hueBlue;
    if (kost is MixedKost) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueRed;
  }

  void _onMarkerTapped(BaseKost kost) {
    setState(() {
      _selectedKost = kost;
    });

    // Animate camera to marker
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(kost.latitude, kost.longitude), 16),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Fit bounds to show all markers
    if (widget.kosts.isNotEmpty) {
      _fitMarkersInView();
    }
  }

  void _fitMarkersInView() {
    if (_mapController == null || widget.kosts.isEmpty) return;

    double minLat = widget.kosts.first.latitude;
    double maxLat = widget.kosts.first.latitude;
    double minLng = widget.kosts.first.longitude;
    double maxLng = widget.kosts.first.longitude;

    for (var kost in widget.kosts) {
      if (kost.latitude < minLat) minLat = kost.latitude;
      if (kost.latitude > maxLat) maxLat = kost.latitude;
      if (kost.longitude < minLng) minLng = kost.longitude;
      if (kost.longitude > maxLng) maxLng = kost.longitude;
    }

    // Include UNESA location
    if (_unesaLocation.latitude < minLat) minLat = _unesaLocation.latitude;
    if (_unesaLocation.latitude > maxLat) maxLat = _unesaLocation.latitude;
    if (_unesaLocation.longitude < minLng) minLng = _unesaLocation.longitude;
    if (_unesaLocation.longitude > maxLng) maxLng = _unesaLocation.longitude;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        50, // padding
      ),
    );
  }

  void _moveToMyLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  String _calculateDistance(BaseKost kost) {
    if (_currentPosition == null) {
      return '${kost.calculateDistanceTo(_unesaLocation.latitude, _unesaLocation.longitude).toStringAsFixed(1)} km dari kampus';
    }

    return '${kost.calculateDistanceTo(_currentPosition!.latitude, _currentPosition!.longitude).toStringAsFixed(1)} km dari Anda';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map (on web you must provide Maps JS API key in web/index.html)
          if (!kIsWeb)
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _unesaLocation,
                zoom: 13,
              ),
              markers: _markers,
              mapType: _currentMapType,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
            )
          else
            // Web fallback: avoid runtime JS exception when Google Maps JS isn't loaded.
            Container(
              color: Colors.grey[200],
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Peta tidak tersedia di web tanpa API key',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Untuk menampilkan Google Maps di web, tambahkan Maps JavaScript API key di file web/index.html dan aktifkan Maps JavaScript API pada Google Cloud Console.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('https://www.google.com/maps');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Buka Google Maps di browser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top bar with back button and map controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                16,
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
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: const Color(0xFF6B46C1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF6B46C1),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.kosts.length} Kost',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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

          // Map control buttons
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                // My location button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _moveToMyLocation,
                    color: const Color(0xFF6B46C1),
                    tooltip: 'Lokasi Saya',
                  ),
                ),
                const SizedBox(height: 8),
                // Map type toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _currentMapType == MapType.normal
                          ? Icons.satellite
                          : Icons.map,
                    ),
                    onPressed: _toggleMapType,
                    color: const Color(0xFF6B46C1),
                    tooltip: 'Ganti Tampilan',
                  ),
                ),
                const SizedBox(height: 8),
                // Fit bounds button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: _fitMarkersInView,
                    color: const Color(0xFF6B46C1),
                    tooltip: 'Tampilkan Semua',
                  ),
                ),
              ],
            ),
          ),

          // Legend
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legenda',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.pink, 'Kost Putri'),
                  _buildLegendItem(Colors.blue, 'Kost Putra'),
                  _buildLegendItem(Colors.purple, 'Kost Campur'),
                  _buildLegendItem(Colors.green, 'Kampus UNESA'),
                ],
              ),
            ),
          ),

          // Selected kost card at bottom
          if (_selectedKost != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectedKostCard(),
            ),
          // Loading overlay while fetching location
          if (_isLoadingLocation)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSelectedKostCard() {
    final kost = _selectedKost!;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kost.getPrimaryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    kost.getKostIcon(),
                    color: kost.getPrimaryColor(),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kost.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _calculateDistance(kost),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            kost.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            kost.getFormattedPrice(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kost.getPrimaryColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedKost = null),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KostDetailScreen(
                            kost: kost,
                            initialImageIndex: 0,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kost.getPrimaryColor(),
                      side: BorderSide(color: kost.getPrimaryColor()),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Detail'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to directions in Google Maps
                      // launchUrl for navigation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kost.getPrimaryColor(),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Rute'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
