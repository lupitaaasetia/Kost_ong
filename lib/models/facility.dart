// models/facility.dart
import 'package:flutter/material.dart';
import 'base_entity.dart';

enum FacilityType {
  bathroom,
  cooling,
  electrical,
  internet,
  parking,
  kitchen,
  security,
  other,
  general,
  room,
  service,
}

class Facility extends BaseEntity {
  String _name;
  FacilityType _type;
  IconData _icon;
  Color _color;
  bool _isAvailable;
  double? _additionalCost;

  Facility({
    required super.id,
    required String name,
    required FacilityType type,
    required IconData icon,
    required Color color,
    bool isAvailable = true,
    double? additionalCost,
  }) : _name = name,
       _type = type,
       _icon = icon,
       _color = color,
       _isAvailable = isAvailable,
       _additionalCost = additionalCost;

  // Getters (Encapsulation)
  String get name => _name;
  FacilityType get type => _type;
  IconData get icon => _icon;
  Color get color => _color;
  bool get isAvailable => _isAvailable;
  double? get additionalCost => _additionalCost;

  // Setters with validation (Encapsulation)
  set name(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Facility name cannot be empty');
    }
    _name = value.trim();
    updatedAt = DateTime.now();
  }

  set isAvailable(bool value) {
    _isAvailable = value;
    updatedAt = DateTime.now();
  }

  set additionalCost(double? value) {
    if (value != null && value < 0) {
      throw ArgumentError('Additional cost cannot be negative');
    }
    _additionalCost = value;
    updatedAt = DateTime.now();
  }

  // Override abstract methods (Polymorphism)
  @override
  String getDisplayName() => _name;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'type': _type.name,
      'iconCodePoint': _icon.codePoint,
      // ignore: deprecated_member_use
      'colorValue': _color.value,
      'isAvailable': _isAvailable,
      'additionalCost': _additionalCost,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Factory method for creating facilities from string
  factory Facility.fromString(String facilityName) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final lowerName = facilityName.toLowerCase();

    if (lowerName.contains('kamar mandi dalam')) {
      return Facility(
        id: id,
        name: facilityName,
        type: FacilityType.bathroom,
        icon: Icons.bathroom,
        color: Colors.blue,
      );
    } else if (lowerName.contains('ac')) {
      return Facility(
        id: id,
        name: facilityName,
        type: FacilityType.cooling,
        icon: Icons.ac_unit,
        color: Colors.cyan,
        additionalCost: 50000,
      );
    } else if (lowerName.contains('wifi') || lowerName.contains('internet')) {
      return Facility(
        id: id,
        name: facilityName,
        type: FacilityType.internet,
        icon: Icons.wifi,
        color: Colors.purple,
      );
    } else if (lowerName.contains('listrik')) {
      return Facility(
        id: id,
        name: facilityName,
        type: FacilityType.electrical,
        icon: Icons.electrical_services,
        color: Colors.amber,
      );
    } else {
      return Facility(
        id: id,
        name: facilityName,
        type: FacilityType.other,
        icon: Icons.check_circle,
        color: Colors.green,
      );
    }
  }

  @override
  String toString() {
    return 'Facility(name: $_name, type: ${_type.name}, available: $_isAvailable)';
  }
}
