import 'dart:math';
import 'package:flutter/material.dart';
import 'base_entity.dart';
import 'facility.dart';

enum KostStatus {
  available('Tersedia'),
  full('Penuh'),
  maintenance('Maintenance'),
  inactive('Tidak Aktif');

  const KostStatus(this.displayName);
  final String displayName;
}

// Base Kost class with full OOP implementation
abstract class BaseKost extends BaseEntity implements Searchable, Sortable {
  String _name;
  String _address;
  String _description;
  int _pricePerMonth;
  double _rating;
  final List<Facility> _facilities;
  String _phoneNumber;
  final double _latitude;
  final double _longitude;
  final List<String> _imageUrls;
  String _ownerEmail;
  KostStatus _status;

  BaseKost({
    required super.id,
    required String name,
    required String address,
    required String description,
    required int pricePerMonth,
    required double rating,
    required List<Facility> facilities,
    required String phoneNumber,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
    String ownerEmail = '',
    KostStatus status = KostStatus.available,
  }) : _name = name,
       _address = address,
       _description = description,
       _pricePerMonth = pricePerMonth,
       _rating = rating,
       _facilities = List.from(facilities),
       _phoneNumber = phoneNumber,
       _latitude = latitude,
       _longitude = longitude,
       _imageUrls = List.from(imageUrls),
       _ownerEmail = ownerEmail,
       _status = status {
    _validateInputs();
  }

  // Getters (Encapsulation)
  String get name => _name;
  String get address => _address;
  String get description => _description;
  int get pricePerMonth => _pricePerMonth;
  double get rating => _rating;
  List<Facility> get facilities => List.unmodifiable(_facilities);
  String get phoneNumber => _phoneNumber;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get ownerEmail => _ownerEmail;
  KostStatus get status => _status;
  List<String> get imageUrls => List.unmodifiable(_imageUrls);

  // Setters with validation (Encapsulation)
  set name(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Kost name cannot be empty');
    }
    _name = value.trim();
    updatedAt = DateTime.now();
  }

  set address(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Address cannot be empty');
    }
    _address = value.trim();
    updatedAt = DateTime.now();
  }

  set description(String value) {
    _description = value.trim();
    updatedAt = DateTime.now();
  }

  set pricePerMonth(int value) {
    if (value < 0) {
      throw ArgumentError('Price cannot be negative');
    }
    if (value > 50000000) {
      throw ArgumentError('Price too high');
    }
    _pricePerMonth = value;
    updatedAt = DateTime.now();
  }

  set rating(double value) {
    if (value < 0 || value > 5) {
      throw ArgumentError('Rating must be between 0 and 5');
    }
    _rating = value;
    updatedAt = DateTime.now();
  }

  set phoneNumber(String value) {
    if (!_isValidPhoneNumber(value)) {
      throw ArgumentError('Invalid phone number format');
    }
    _phoneNumber = value;
    updatedAt = DateTime.now();
  }

  set status(KostStatus value) {
    _status = value;
    updatedAt = DateTime.now();
  }

  // Private validation methods
  void _validateInputs() {
    if (_name.trim().isEmpty) throw ArgumentError('Name cannot be empty');
    if (_address.trim().isEmpty) throw ArgumentError('Address cannot be empty');
    if (_pricePerMonth < 0) throw ArgumentError('Price cannot be negative');
    if (_rating < 0 || _rating > 5) throw ArgumentError('Invalid rating');
    if (!_isValidPhoneNumber(_phoneNumber)) {
      throw ArgumentError('Invalid phone');
    }
  }

  bool _isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[\+]?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-]'), ''));
  }

  // Facility management methods
  void addFacility(Facility facility) {
    if (!_facilities.contains(facility)) {
      _facilities.add(facility);
      updatedAt = DateTime.now();
    }
  }

  void removeFacility(Facility facility) {
    if (_facilities.remove(facility)) {
      updatedAt = DateTime.now();
    }
  }

  bool hasFacility(String facilityName) {
    return _facilities.any(
      (facility) =>
          facility.name.toLowerCase().contains(facilityName.toLowerCase()),
    );
  }

  // Utility methods
  String getFormattedPrice() {
    final formatter = _pricePerMonth.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatter/bulan';
  }

  double calculateDistanceTo(double targetLat, double targetLng) {
    const double earthRadius = 6371; // km
    double dLat = _degreesToRadians(targetLat - _latitude);
    double dLng = _degreesToRadians(targetLng - _longitude);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(_latitude)) *
            cos(_degreesToRadians(targetLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180);

  // Abstract methods for polymorphism
  String getKostType();
  Color getPrimaryColor();
  IconData getKostIcon();

  // Template method pattern
  String getFullInfo() {
    return '${getKostType()}: $_name - ${getFormattedPrice()}';
  }

  // Override abstract methods (Polymorphism)
  @override
  String getDisplayName() => _name;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'address': _address,
      'description': _description,
      'pricePerMonth': _pricePerMonth,
      'rating': _rating,
      'facilities': _facilities.map((f) => f.toJson()).toList(),
      'phoneNumber': _phoneNumber,
      'ownerEmail': _ownerEmail,
      'latitude': _latitude,
      'longitude': _longitude,
      'imageUrls': _imageUrls,
      'kostType': getKostType(),
      'status': _status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Implement Searchable interface
  @override
  bool matchesQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return _name.toLowerCase().contains(lowerQuery) ||
        _address.toLowerCase().contains(lowerQuery) ||
        _description.toLowerCase().contains(lowerQuery) ||
        _facilities.any((f) => f.name.toLowerCase().contains(lowerQuery));
  }

  @override
  List<String> getSearchableFields() {
    List<String> fields = [_name, _address, _description];
    fields.addAll(_facilities.map((f) => f.name));
    return fields;
  }

  // Implement Sortable interface
  @override
  int compareTo(Sortable other) {
    if (other is BaseKost) {
      return _name.compareTo(other._name);
    }
    return 0;
  }

  // Method overloading simulation with optional parameters
  int compareByPrice(BaseKost other, {bool ascending = true}) {
    int result = _pricePerMonth.compareTo(other._pricePerMonth);
    return ascending ? result : -result;
  }

  int compareByRating(BaseKost other, {bool ascending = false}) {
    int result = _rating.compareTo(other._rating);
    return ascending ? result : -result;
  }

  int compareByDistance(
    BaseKost other,
    double refLat,
    double refLng, {
    bool ascending = true,
  }) {
    double thisDist = calculateDistanceTo(refLat, refLng);
    double otherDist = other.calculateDistanceTo(refLat, refLng);
    int result = thisDist.compareTo(otherDist);
    return ascending ? result : -result;
  }
}

// Concrete Kost implementations (Inheritance)
class FemaleKost extends BaseKost {
  bool _hasSecurityGuard;
  String _curfewTime;

  FemaleKost({
    required super.id,
    required super.name,
    required super.address,
    required super.description,
    required super.pricePerMonth,
    required super.rating,
    required super.facilities,
    required super.phoneNumber,
    required super.latitude,
    required super.longitude,
    required super.imageUrls,
    bool hasSecurityGuard = false,
    String curfewTime = '22:00',
    super.status,
  }) : _hasSecurityGuard = hasSecurityGuard,
       _curfewTime = curfewTime;

  // Additional getters/setters for female kost
  bool get hasSecurityGuard => _hasSecurityGuard;
  String get curfewTime => _curfewTime;

  set hasSecurityGuard(bool value) {
    _hasSecurityGuard = value;
    updatedAt = DateTime.now();
  }

  set curfewTime(String value) {
    _curfewTime = value;
    updatedAt = DateTime.now();
  }

  // Override abstract methods (Polymorphism)
  @override
  String getKostType() => 'Kost Perempuan';

  @override
  Color getPrimaryColor() => const Color(0xFFE91E63);

  @override
  IconData getKostIcon() => Icons.woman;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['hasSecurityGuard'] = _hasSecurityGuard;
    json['curfewTime'] = _curfewTime;
    return json;
  }
}

class MaleKost extends BaseKost {
  bool _allowsSmoking;
  bool _hasWorkspace;

  MaleKost({
    required super.id,
    required super.name,
    required super.address,
    required super.description,
    required super.pricePerMonth,
    required super.rating,
    required super.facilities,
    required super.phoneNumber,
    required super.latitude,
    required super.longitude,
    required super.imageUrls,
    bool allowsSmoking = false,
    bool hasWorkspace = false,
    super.status,
  }) : _allowsSmoking = allowsSmoking,
       _hasWorkspace = hasWorkspace;

  // Additional getters/setters
  bool get allowsSmoking => _allowsSmoking;
  bool get hasWorkspace => _hasWorkspace;

  set allowsSmoking(bool value) {
    _allowsSmoking = value;
    updatedAt = DateTime.now();
  }

  set hasWorkspace(bool value) {
    _hasWorkspace = value;
    updatedAt = DateTime.now();
  }

  // Override abstract methods (Polymorphism)
  @override
  String getKostType() => 'Kost Laki-laki';

  @override
  Color getPrimaryColor() => const Color(0xFF2196F3);

  @override
  IconData getKostIcon() => Icons.man;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['allowsSmoking'] = _allowsSmoking;
    json['hasWorkspace'] = _hasWorkspace;
    return json;
  }
}

class MixedKost extends BaseKost {
  bool _hasSeparateEntrance;
  int _maleRooms;
  int _femaleRooms;

  MixedKost({
    required super.id,
    required super.name,
    required super.address,
    required super.description,
    required super.pricePerMonth,
    required super.rating,
    required super.facilities,
    required super.phoneNumber,
    required super.latitude,
    required super.longitude,
    required super.imageUrls,
    bool hasSeparateEntrance = true,
    int maleRooms = 5,
    int femaleRooms = 5,
    super.status,
  }) : _hasSeparateEntrance = hasSeparateEntrance,
       _maleRooms = maleRooms,
       _femaleRooms = femaleRooms;

  // Additional getters/setters
  bool get hasSeparateEntrance => _hasSeparateEntrance;
  int get maleRooms => _maleRooms;
  int get femaleRooms => _femaleRooms;
  int get totalRooms => _maleRooms + _femaleRooms;

  set hasSeparateEntrance(bool value) {
    _hasSeparateEntrance = value;
    updatedAt = DateTime.now();
  }

  set maleRooms(int value) {
    if (value < 0) throw ArgumentError('Male rooms cannot be negative');
    _maleRooms = value;
    updatedAt = DateTime.now();
  }

  set femaleRooms(int value) {
    if (value < 0) throw ArgumentError('Female rooms cannot be negative');
    _femaleRooms = value;
    updatedAt = DateTime.now();
  }

  // Override abstract methods (Polymorphism)
  @override
  String getKostType() => 'Kost Campur';

  @override
  Color getPrimaryColor() => const Color(0xFF4CAF50);

  @override
  IconData getKostIcon() => Icons.people;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['hasSeparateEntrance'] = _hasSeparateEntrance;
    json['maleRooms'] = _maleRooms;
    json['femaleRooms'] = _femaleRooms;
    return json;
  }
}
