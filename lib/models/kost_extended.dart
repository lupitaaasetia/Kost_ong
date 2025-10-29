class AdditionalCost {
  final String name;
  final double amount;
  final bool isRequired;
  final String? description;

  AdditionalCost({
    required this.name,
    required this.amount,
    required this.isRequired,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'isRequired': isRequired,
      'description': description,
    };
  }

  factory AdditionalCost.fromJson(Map<String, dynamic> json) {
    return AdditionalCost(
      name: json['name'],
      amount: json['amount'].toDouble(),
      isRequired: json['isRequired'],
      description: json['description'],
    );
  }
}

// House rules
class HouseRule {
  final String icon;
  final String title;
  final String description;
  final bool isRestriction;

  HouseRule({
    required this.icon,
    required this.title,
    required this.description,
    required this.isRestriction,
  });

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'title': title,
      'description': description,
      'isRestriction': isRestriction,
    };
  }

  factory HouseRule.fromJson(Map<String, dynamic> json) {
    return HouseRule(
      icon: json['icon'],
      title: json['title'],
      description: json['description'],
      isRestriction: json['isRestriction'],
    );
  }
}

// Room availability
class RoomAvailability {
  final int totalRooms;
  final int occupiedRooms;
  final DateTime? nextAvailableDate;
  final List<String> availableRoomNumbers;

  RoomAvailability({
    required this.totalRooms,
    required this.occupiedRooms,
    this.nextAvailableDate,
    required this.availableRoomNumbers,
  });

  int get availableRooms => totalRooms - occupiedRooms;
  bool get hasAvailableRooms => availableRooms > 0;
  double get occupancyRate => (occupiedRooms / totalRooms) * 100;

  Map<String, dynamic> toJson() {
    return {
      'totalRooms': totalRooms,
      'occupiedRooms': occupiedRooms,
      'nextAvailableDate': nextAvailableDate?.toIso8601String(),
      'availableRoomNumbers': availableRoomNumbers,
    };
  }

  factory RoomAvailability.fromJson(Map<String, dynamic> json) {
    return RoomAvailability(
      totalRooms: json['totalRooms'],
      occupiedRooms: json['occupiedRooms'],
      nextAvailableDate: json['nextAvailableDate'] != null
          ? DateTime.parse(json['nextAvailableDate'])
          : null,
      availableRoomNumbers: List<String>.from(json['availableRoomNumbers']),
    );
  }
}

// Nearby place
class NearbyPlace {
  final String name;
  final String type;
  final double distance;
  final String? icon;

  NearbyPlace({
    required this.name,
    required this.type,
    required this.distance,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type, 'distance': distance, 'icon': icon};
  }

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      name: json['name'],
      type: json['type'],
      distance: json['distance'].toDouble(),
      icon: json['icon'],
    );
  }
}

// UNESA Discount
class UNESADiscount {
  final bool isAvailable;
  final double discountPercentage;
  final double discountAmount;
  final String? terms;
  final DateTime? validUntil;

  UNESADiscount({
    required this.isAvailable,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.terms,
    this.validUntil,
  });

  int getDiscountedPrice(int originalPrice) {
    if (!isAvailable) return originalPrice;

    if (discountPercentage > 0) {
      return (originalPrice * (1 - discountPercentage / 100)).round();
    }

    return (originalPrice - discountAmount).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'terms': terms,
      'validUntil': validUntil?.toIso8601String(),
    };
  }

  factory UNESADiscount.fromJson(Map<String, dynamic> json) {
    return UNESADiscount(
      isAvailable: json['isAvailable'],
      discountPercentage: json['discountPercentage']?.toDouble() ?? 0,
      discountAmount: json['discountAmount']?.toDouble() ?? 0,
      terms: json['terms'],
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
    );
  }
}

// Extended Kost with all details
class ExtendedKostDetails {
  final String kostId;
  final List<String> imageUrls;
  final List<AdditionalCost> additionalCosts;
  final double depositAmount;
  final List<HouseRule> houseRules;
  final RoomAvailability roomAvailability;
  final List<NearbyPlace> nearbyPlaces;
  final UNESADiscount unesaDiscount;
  final String? virtualTourUrl;
  final List<String> highlights;
  final Map<String, String> specifications;

  ExtendedKostDetails({
    required this.kostId,
    required this.imageUrls,
    required this.additionalCosts,
    required this.depositAmount,
    required this.houseRules,
    required this.roomAvailability,
    required this.nearbyPlaces,
    required this.unesaDiscount,
    this.virtualTourUrl,
    required this.highlights,
    required this.specifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'kostId': kostId,
      'imageUrls': imageUrls,
      'additionalCosts': additionalCosts.map((c) => c.toJson()).toList(),
      'depositAmount': depositAmount,
      'houseRules': houseRules.map((r) => r.toJson()).toList(),
      'roomAvailability': roomAvailability.toJson(),
      'nearbyPlaces': nearbyPlaces.map((p) => p.toJson()).toList(),
      'unesaDiscount': unesaDiscount.toJson(),
      'virtualTourUrl': virtualTourUrl,
      'highlights': highlights,
      'specifications': specifications,
    };
  }

  factory ExtendedKostDetails.fromJson(Map<String, dynamic> json) {
    return ExtendedKostDetails(
      kostId: json['kostId'],
      imageUrls: List<String>.from(json['imageUrls']),
      additionalCosts: (json['additionalCosts'] as List)
          .map((c) => AdditionalCost.fromJson(c))
          .toList(),
      depositAmount: json['depositAmount'].toDouble(),
      houseRules: (json['houseRules'] as List)
          .map((r) => HouseRule.fromJson(r))
          .toList(),
      roomAvailability: RoomAvailability.fromJson(json['roomAvailability']),
      nearbyPlaces: (json['nearbyPlaces'] as List)
          .map((p) => NearbyPlace.fromJson(p))
          .toList(),
      unesaDiscount: UNESADiscount.fromJson(json['unesaDiscount']),
      virtualTourUrl: json['virtualTourUrl'],
      highlights: List<String>.from(json['highlights']),
      specifications: Map<String, String>.from(json['specifications']),
    );
  }

  // Calculate total monthly cost
  double getTotalMonthlyCost(int basePrice) {
    double total = basePrice.toDouble();
    for (var cost in additionalCosts) {
      if (cost.isRequired) {
        total += cost.amount;
      }
    }
    return total;
  }

  // Get required costs only
  List<AdditionalCost> getRequiredCosts() {
    return additionalCosts.where((c) => c.isRequired).toList();
  }

  // Get optional costs
  List<AdditionalCost> getOptionalCosts() {
    return additionalCosts.where((c) => !c.isRequired).toList();
  }

  // Get restrictions
  List<HouseRule> getRestrictions() {
    return houseRules.where((r) => r.isRestriction).toList();
  }

  // Get amenities/benefits
  List<HouseRule> getAmenities() {
    return houseRules.where((r) => !r.isRestriction).toList();
  }

  // Get nearby places by type
  List<NearbyPlace> getNearbyPlacesByType(String type) {
    return nearbyPlaces.where((p) => p.type == type).toList();
  }

  // Calculate deposit in rupiah
  double getDepositAmount(int monthlyPrice) {
    return monthlyPrice * depositAmount;
  }
}

// Factory class for creating demo data
class KostDetailsFactory {
  static ExtendedKostDetails createDemoDetails(String kostId, int basePrice) {
    return ExtendedKostDetails(
      kostId: kostId,
      imageUrls: [
        'https://via.placeholder.com/800x600/6B46C1/FFFFFF?text=Kamar+1',
        'https://via.placeholder.com/800x600/8B5CF6/FFFFFF?text=Kamar+2',
        'https://via.placeholder.com/800x600/EC4899/FFFFFF?text=Kamar+Mandi',
        'https://via.placeholder.com/800x600/F59E0B/FFFFFF?text=Area+Bersama',
        'https://via.placeholder.com/800x600/10B981/FFFFFF?text=Dapur',
      ],
      additionalCosts: [
        AdditionalCost(
          name: 'Listrik',
          amount: 50000,
          isRequired: true,
          description: 'Biaya listrik per bulan (estimasi)',
        ),
        AdditionalCost(
          name: 'Air',
          amount: 30000,
          isRequired: true,
          description: 'Biaya air bersih per bulan',
        ),
        AdditionalCost(
          name: 'Service Charge',
          amount: 50000,
          isRequired: true,
          description: 'Biaya pemeliharaan dan kebersihan',
        ),
        AdditionalCost(
          name: 'Laundry',
          amount: 5000,
          isRequired: false,
          description: 'Per kg (opsional)',
        ),
        AdditionalCost(
          name: 'Parkir Motor',
          amount: 25000,
          isRequired: false,
          description: 'Per bulan (opsional)',
        ),
      ],
      depositAmount: 1.0, // 1 month
      houseRules: [
        HouseRule(
          icon: '🚭',
          title: 'Dilarang Merokok',
          description: 'Dilarang merokok di dalam kamar dan area bersama',
          isRestriction: true,
        ),
        HouseRule(
          icon: '🔇',
          title: 'Jam Malam',
          description: 'Tamu tidak diperbolehkan menginap',
          isRestriction: true,
        ),
        HouseRule(
          icon: '🐕',
          title: 'Tidak Boleh Bawa Hewan',
          description: 'Tidak diperkenankan membawa hewan peliharaan',
          isRestriction: true,
        ),
        HouseRule(
          icon: '🍺',
          title: 'Dilarang Minuman Keras',
          description: 'Dilarang membawa dan mengonsumsi minuman keras',
          isRestriction: true,
        ),
        HouseRule(
          icon: '✨',
          title: 'Kebersihan Rutin',
          description: 'Pembersihan area bersama setiap hari',
          isRestriction: false,
        ),
        HouseRule(
          icon: '🔒',
          title: 'Keamanan 24 Jam',
          description: 'Penjagaan dan CCTV aktif 24/7',
          isRestriction: false,
        ),
        HouseRule(
          icon: '📦',
          title: 'Titip Barang',
          description: 'Layanan penitipan paket gratis',
          isRestriction: false,
        ),
      ],
      roomAvailability: RoomAvailability(
        totalRooms: 12,
        occupiedRooms: 8,
        nextAvailableDate: DateTime.now().add(const Duration(days: 15)),
        availableRoomNumbers: ['A1', 'A3', 'B2', 'C4'],
      ),
      nearbyPlaces: [
        NearbyPlace(
          name: 'Indomaret',
          type: 'minimarket',
          distance: 0.2,
          icon: '🏪',
        ),
        NearbyPlace(
          name: 'Alfamart',
          type: 'minimarket',
          distance: 0.3,
          icon: '🏪',
        ),
        NearbyPlace(
          name: 'Warung Makan Bu Sri',
          type: 'restaurant',
          distance: 0.1,
          icon: '🍽️',
        ),
        NearbyPlace(name: 'ATM BCA', type: 'atm', distance: 0.4, icon: '🏧'),
        NearbyPlace(
          name: 'ATM Mandiri',
          type: 'atm',
          distance: 0.5,
          icon: '🏧',
        ),
        NearbyPlace(
          name: 'Puskesmas Magetan',
          type: 'hospital',
          distance: 1.2,
          icon: '🏥',
        ),
        NearbyPlace(
          name: 'Apotek Kimia Farma',
          type: 'pharmacy',
          distance: 0.6,
          icon: '💊',
        ),
        NearbyPlace(
          name: 'Laundry Express',
          type: 'laundry',
          distance: 0.3,
          icon: '👕',
        ),
      ],
      unesaDiscount: UNESADiscount(
        isAvailable: true,
        discountPercentage: 10,
        discountAmount: 0,
        terms:
            'Berlaku untuk mahasiswa UNESA yang terverifikasi. Tunjukkan KTM saat booking.',
        validUntil: DateTime.now().add(const Duration(days: 365)),
      ),
      virtualTourUrl: null,
      highlights: [
        'WiFi 100 Mbps gratis',
        'Air 24 jam',
        'Dekat kampus (500m)',
        'Kamar mandi dalam',
        'Dapur bersama lengkap',
        'Parkir motor luas',
        'Keamanan 24 jam',
        'Area laundry',
      ],
      specifications: {
        'Ukuran Kamar': '3x4 meter',
        'Kasur': 'Single Bed',
        'Lemari': 'Lemari 2 pintu',
        'Meja & Kursi': 'Tersedia',
        'Jendela': 'Ada',
        'Kamar Mandi': 'Dalam',
        'AC': 'Opsional (+Rp 50k/bulan)',
        'Listrik': 'Token 2200 watt',
      },
    );
  }

  // Create custom details
  static ExtendedKostDetails createCustomDetails({
    required String kostId,
    required List<String> imageUrls,
    required List<AdditionalCost> additionalCosts,
    required double depositAmount,
    required List<HouseRule> houseRules,
    required RoomAvailability roomAvailability,
    required List<NearbyPlace> nearbyPlaces,
    required UNESADiscount unesaDiscount,
    String? virtualTourUrl,
    required List<String> highlights,
    required Map<String, String> specifications,
  }) {
    return ExtendedKostDetails(
      kostId: kostId,
      imageUrls: imageUrls,
      additionalCosts: additionalCosts,
      depositAmount: depositAmount,
      houseRules: houseRules,
      roomAvailability: roomAvailability,
      nearbyPlaces: nearbyPlaces,
      unesaDiscount: unesaDiscount,
      virtualTourUrl: virtualTourUrl,
      highlights: highlights,
      specifications: specifications,
    );
  }
}
