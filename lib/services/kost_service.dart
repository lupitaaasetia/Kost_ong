// services/kost_service.dart
import '../models/facility.dart';
import '../models/kost.dart';

enum SortCriteria { name, price, rating, type, distance, createdDate }

// Statistics model
class KostStatistics {
  final int totalKost;
  final double averagePrice;
  final double averageRating;
  final String priceRange;
  final Map<String, int> kostTypeDistribution;
  final List<String> topFacilities;

  KostStatistics({
    required this.totalKost,
    required this.averagePrice,
    required this.averageRating,
    required this.priceRange,
    required this.kostTypeDistribution,
    required this.topFacilities,
  });
}

// Main service class with business logic
class KostService {
  List<BaseKost> _allKost = [];

  // Singleton pattern
  static final KostService _instance = KostService._internal();
  factory KostService() => _instance;
  KostService._internal();

  // Getter for all kost data
  List<BaseKost> get allKost => List.unmodifiable(_allKost);

  // Initialize with dummy data
  void initializeData() {
    if (_allKost.isNotEmpty) return; // Already initialized

    _allKost = [
      // Female Kosts
      FemaleKost(
        id: '1',
        imageUrls: [
          "https://lh3.googleusercontent.com/p/AF1QipN2BGNUPI1-9nxLbaHQgfcThUx7aRPRKy78_TyG=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipMXrjpVhIqNgp6smMsPJrIzkdneTOWT1S3U_fnX=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipNKdgkGKe4SZ2rHspDwNsohXDf_0mUfwOb5iLhm=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipN8Soy2KWpmentMu763ylcc9SbAynlOO6wo5RAc=s1360-w1360-h1020-rw",
        ],
        name: 'Kost Risma',
        address:
            'Jl. Barat, Kleco, Mranggen, Kec. Maospati, Kabupaten Magetan, Jawa Timur 63392',
        description: 'Kost nyaman khusus putri dengan keamanan 24 jam',
        pricePerMonth: 600000,
        rating: 4.5,
        facilities: [
          Facility.fromString('Kamar Mandi Dalam'),
          Facility.fromString('WiFi'),
          Facility.fromString('Parkir Motor'),
          Facility.fromString('Dapur Bersama'),
        ],
        phoneNumber: '081282352480',
        latitude: -7.5889999,
        longitude: 111.4375789,
        hasSecurityGuard: true,
        curfewTime: '22:00',
      ),

      FemaleKost(
        id: '2',
        imageUrls: [
          "https://lh3.googleusercontent.com/p/AF1QipMVu-bt-ARMY1SzCDrrEGq_QeE3ekehY7ldsyG_=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipMCwAxx8vIHIKWOCP7jtQzkTN3HvzpgBPATc22q=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipM1jk1YDLziJcw55DISIL5lhFDvb3slBNSu-8eF=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipPQ43YHk-ZyvSvWz51GH0gGuuiZy2ZoTx3WD9iN=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipNe-EVxB9v7D3VsMzGH6cCyR0Hca9TBIIh4wb87=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipOcw8gj7GH6UXaBDtAJMwtfggNWrRIM-gjLGLMY=s1360-w1360-h1020-rw",
        ],
        name: 'Kost Griya Raya',
        address:
            'Jl. Krido IV No.161 03, RW.01, Mranggen, Kec. Maospati, Kabupaten Magetan, Jawa Timur 63392',
        description: 'Kost eksklusif untuk mahasiswi dengan fasilitas lengkap',
        pricePerMonth: 600000,
        rating: 5,
        facilities: [
          Facility.fromString('Kamar Mandi Dalam'),
          Facility.fromString('WiFi'),
          Facility.fromString('Include Listrik'),
          Facility.fromString('Parkir Motor'),
          Facility.fromString('Kipas Angin '),
        ],
        phoneNumber: '08123408922',
        latitude: -7.5903263,
        longitude: 111.4383227,
        hasSecurityGuard: true,
        curfewTime: '22:00',
      ),

      // Male Kosts
      MaleKost(
        id: '3',
        imageUrls: [
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4nqj7y9RRcXO8MKDqAgFSxZxf6Vccrcv_WMRad1Pf50CGQP8MU2UjIYLjeHBQ9i9wfqtpXV27qRKC3oyCWt7Wr6nvyztY9QhO67Wj6XKuoK4FXNTi2S4EhWp24-H5Iu8xVykjBPn=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4nr9PjkhIQy2FKJIfgTQQtJG7cmNlS6JrmPjucjZeBaGz8OAy2GrpHRnnPzL25ty9jzXM09rKyAJLogAayJXIF3D84LyWJcwc545DRuLFvO1uK0U433QamXi8HKBmWl8QFQB5Paqmw=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4nq9kjb7C5GNQQYl6xyJDRKK1D0K2OZhj3CrtceRVXW2zbyx3PDJMUuzpzrfISKyQm_eV1P0aY1aQJ6HD3HmRpHonPcL57xSPymCVdXyzlas5BO3kn2v5xR-BkvOwbKOv8Alvu0rNA=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4nqijNyUSVftXDHT1yaGw25wYsUxqmx4bcXZFuWrQJ5qAI_a2YmzpyDY2qvP0IIMqWWIEKKOZN-8eRPQp5iYpEekj6VtV-EGNr85pST4WpmQwEqwB0GXq4pGYh9FG6qHcCuqtB6G=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4no8Mj15SCdCk4fnSv9Sffx3uueygLvhNy_hKXA3MBgVNSvhcVvNBnaV8hvsP-kugB93n-z21mRTEJEM8GrxVHUWNIy5y_6mYJ90RNoK0RXx23uVyIe_IXx2-vfkikOWIj96blAM=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4nptimWB1ehRCqt1DKUPM4nky-DwHwvIeSGoSvcbYdD4bdGvi368NRBA3x_CoBvlQPjppPcI8IA4z76wdaqfQeNzH21kSMXFCzDJRpvjfXEkQmEanAlWZzxvIT0Vi2Y2lkIGrCTwhQ=s1360-w1360-h1020-rw",
        ],
        name: 'Kost Rajawali 957 ',
        address:
            'Jl. Rajawali No.957, Kleco, Maospati, Kec. Maospati, Kabupaten Magetan, Jawa Timur 63392n',
        description: 'Kost strategis untuk mahasiswa dengan suasana kondusif',
        pricePerMonth: 500000,
        rating: 4.8,
        facilities: [
          Facility.fromString('Kamar Mandi Luar'),
          Facility.fromString('Kipas Angin'),
          Facility.fromString('WiFi'),
          Facility.fromString('Parkir Motor'),
        ],
        phoneNumber: '081283394144',
        latitude: -7.5980831,
        longitude: 111.4386068,
        allowsSmoking: false,
        hasWorkspace: true,
      ),

      MaleKost(
        id: '4',
        imageUrls: [
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4nrXkFiUm9Xs4wnhw4fML5OxiqVEp7Mvv4TmdhB5vZOWV14xVPe6ApFEHjayTEnFooxMZ9v-eVk5P8WWTpiA0M2IISXxT8jNfUjmEGtoJ7umx7k7NXTl7Sfy-IgA9xWY0OFe8QuuoQDX_67Z=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4npu64VC_LGZ60XH1s8tO0BrZNaox54g0IvZxq21f-hHkVYRd87dh2Tqf5l-MAheWjJiXx9t7sUMRklBbwHQl8QIK5y0B-gZ8WCX15em7lGyaTyrIQKc_xdjfXWcsA4TiUWSr_szocXoUJxv=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4noh7eovGnYnNwzUFP6wexjzp9VGbHMopuJdJaoZ3agZ7Y0QMSCdCY7Cyn2oSumhi8j7bq4GjQaA0gBINpJlv876Hk-Gske70zv7TVvqYe7uPi7PBzMPfdep2Sji8ggEz02zXpMvnGBF9KQ=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4nqXg9ZLUud2GGLtcJnyoszMdrlqjLUeo77_AY8EOGzziyFGtUiEIzIY-uXRLMvLQ2wem0kVDpD7ZMkcnKizMfk9UJpmAXMzW2t8HsXtwiFqJhN7FbENlgVwJGqi0hD6dByGnqeIIQpcvLYs=s1360-w1360-h1020-rw",
        ],
        name: 'Kost Griya Artha Jaya',
        address:
            'CC5Q+HF3, Jl. Karya, RT.02/RW.01, Mranggen, Kec. Maospati, Kabupaten Magetan, Jawa Timur 63392',
        description: 'Kost modern dengan fasilitas workspace untuk mahasiswa',
        pricePerMonth: 500000,
        rating: 4.6,
        facilities: [
          Facility.fromString('Kamar Mandi Dalam'),
          Facility.fromString('WiFi'),
          Facility.fromString('Include Listrik'),
          Facility.fromString('Kipas Angin '),
          Facility.fromString('Parkir Motor'),
        ],
        phoneNumber: '085606858856',
        latitude: -7.59105,
        longitude: 111.43869,
        allowsSmoking: false,
        hasWorkspace: true,
      ),

      // Mixed Kosts
      MixedKost(
        id: '5',
        imageUrls: [
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4npiNQ4T9JxACitnSNJoD9SoHiG4bdsshXJPvgABPWER_F2E1J8vS_i5OQ--NRmmYyZbuNigY00jO0p8F7C6gnRm5k_1N-c53JV8iM87-3rsNzJ6mMFW-HAGz9HJxUWrx6Mnh1X3=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/p/AF1QipNdYa1esfGQI3sIHnLO2X42usNBfijLXLpyH3j9=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4noj-SNH0y8b1tWxPZRJYGntttgfx5pUhY3dBAjyFn2WjzK2A1-Yb644B9QXkbgo_Lint71qmzjxeawKxuBrT15uJcX7Z_x1KAArY6xqBNJiaprWKZiswehuNcXdJh1jTWVIFAN_=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4npre0N2Xp-vG0uSuzgkocOqph3_ZS8qKmeXNHbFCwLiz5Hh-8WpT1MrN-2iJbxF9r2boBxTWJH1RVYmoFS_RtQ3odU73dJwJ1s0PZS5DPVs8TQ8gNro8mCEocSJjNO7wY2keAY=s1360-w1360-h1020-rw",
          "https://lh3.googleusercontent.com/gps-cs-s/AC9h4npcGDG-EaqcuqwFM3j-MMRx3lB1s7QdDi_bt7QrwSYQGb5VRWTblFIE22MJs2IzDOkYKUdy6Fh-cb5vlnPxX5rjDoiQrzHwidEEE50BJLvXjy9dErBNUMHkCAx0EfnYmGPQrXlt=s1360-w1360-h1020-rw",
        ],
        name: 'Kost Yuna',
        address:
            'depan pabrik konveksi, Karangsono, Kec. Bar., Kabupaten Magetan, Jawa Timur 63395',
        description: 'Kost campur dengan pintu masuk terpisah',
        pricePerMonth: 600000,
        rating: 4.4,
        facilities: [
          Facility.fromString('Kamar Mandi Dalam'),
          Facility.fromString('Kipas Angin '),
          Facility.fromString('WiFi'),
          Facility.fromString('Parkir Motor'),
        ],
        phoneNumber: '081335324621',
        latitude: -7.5736684,
        longitude: 111.4432141,
        hasSeparateEntrance: true,
        maleRooms: 6,
        femaleRooms: 4,
      ),
    ];
  }

  // Search functionality
  List<BaseKost> searchKost(String query) {
    if (query.isEmpty) return List.from(_allKost);

    return _allKost.where((kost) => kost.matchesQuery(query)).toList();
  }

  // Sorting functionality
  List<BaseKost> sortKost(
    List<BaseKost> kostList,
    SortCriteria criteria, {
    bool ascending = true,
  }) {
    List<BaseKost> sorted = List.from(kostList);

    switch (criteria) {
      case SortCriteria.name:
        sorted.sort(
          (a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
        break;
      case SortCriteria.price:
        sorted.sort(
          (a, b) => ascending
              ? a.compareByPrice(b)
              : a.compareByPrice(b, ascending: false),
        );
        break;
      case SortCriteria.rating:
        sorted.sort(
          (a, b) => ascending
              ? a.compareByRating(b, ascending: true)
              : a.compareByRating(b),
        );
        break;
      case SortCriteria.type:
        sorted.sort(
          (a, b) => ascending
              ? a.getKostType().compareTo(b.getKostType())
              : b.getKostType().compareTo(a.getKostType()),
        );
        break;
      case SortCriteria.createdDate:
        sorted.sort(
          (a, b) => ascending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
      case SortCriteria.distance:
        // Default reference point (center of Magetan)
        double refLat = -7.6298;
        double refLng = 111.3467;
        sorted.sort(
          (a, b) =>
              a.compareByDistance(b, refLat, refLng, ascending: ascending),
        );
        break;
    }

    return sorted;
  }

  // Filter by facilities
  List<BaseKost> filterByFacilities(List<String> requiredFacilities) {
    return _allKost.where((kost) {
      return requiredFacilities.every((facility) => kost.hasFacility(facility));
    }).toList();
  }

  // Filter by price range
  List<BaseKost> filterByPriceRange(int minPrice, int maxPrice) {
    return _allKost.where((kost) {
      return kost.pricePerMonth >= minPrice && kost.pricePerMonth <= maxPrice;
    }).toList();
  }

  // Filter by rating
  List<BaseKost> filterByRating(double minRating) {
    return _allKost.where((kost) => kost.rating >= minRating).toList();
  }

  // Filter by kost type
  List<BaseKost> filterByType(String kostType) {
    return _allKost.where((kost) => kost.getKostType() == kostType).toList();
  }

  // Get statistics
  KostStatistics getStatistics() {
    if (_allKost.isEmpty) {
      return KostStatistics(
        totalKost: 0,
        averagePrice: 0,
        averageRating: 0,
        priceRange: '0 - 0',
        kostTypeDistribution: {},
        topFacilities: [],
      );
    }

    // Calculate statistics
    int totalKost = _allKost.length;
    double averagePrice =
        _allKost.map((k) => k.pricePerMonth).reduce((a, b) => a + b) /
        totalKost;
    double averageRating =
        _allKost.map((k) => k.rating).reduce((a, b) => a + b) / totalKost;

    int minPrice = _allKost
        .map((k) => k.pricePerMonth)
        .reduce((a, b) => a < b ? a : b);
    int maxPrice = _allKost
        .map((k) => k.pricePerMonth)
        .reduce((a, b) => a > b ? a : b);
    String priceRange =
        'Rp ${_formatPrice(minPrice)} - Rp ${_formatPrice(maxPrice)}';

    // Type distribution
    Map<String, int> typeDistribution = {};
    for (var kost in _allKost) {
      String type = kost.getKostType();
      typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
    }

    // Top facilities
    Map<String, int> facilityCount = {};
    for (var kost in _allKost) {
      for (var facility in kost.facilities) {
        facilityCount[facility.name] = (facilityCount[facility.name] ?? 0) + 1;
      }
    }

    List<String> topFacilities =
        (facilityCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value))
              ..take(10).map((e) => e.key).toList())
            .cast<String>();

    return KostStatistics(
      totalKost: totalKost,
      averagePrice: averagePrice,
      averageRating: averageRating,
      priceRange: priceRange,
      kostTypeDistribution: typeDistribution,
      topFacilities: topFacilities,
    );
  }

  // Get kost by ID
  BaseKost? getKostById(String id) {
    try {
      return _allKost.firstWhere((kost) => kost.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add new kost
  void addKost(BaseKost kost) {
    _allKost.add(kost);
  }

  // Update kost
  bool updateKost(BaseKost updatedKost) {
    int index = _allKost.indexWhere((kost) => kost.id == updatedKost.id);
    if (index != -1) {
      _allKost[index] = updatedKost;
      return true;
    }
    return false;
  }

  // Delete kost
  bool deleteKost(String id) {
    int initialLength = _allKost.length;
    _allKost.removeWhere((kost) => kost.id == id);
    return _allKost.length < initialLength;
  }

  // Private helper method
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Advanced search with multiple criteria
  List<BaseKost> advancedSearch({
    String? query,
    String? kostType,
    int? minPrice,
    int? maxPrice,
    double? minRating,
    List<String>? requiredFacilities,
    SortCriteria sortBy = SortCriteria.name,
    bool ascending = true,
  }) {
    List<BaseKost> results = List.from(_allKost);

    // Apply search query
    if (query != null && query.isNotEmpty) {
      results = results.where((kost) => kost.matchesQuery(query)).toList();
    }

    // Apply type filter
    if (kostType != null && kostType.isNotEmpty && kostType != 'Semua') {
      results = results
          .where((kost) => kost.getKostType() == kostType)
          .toList();
    }

    // Apply price range filter
    if (minPrice != null) {
      results = results
          .where((kost) => kost.pricePerMonth >= minPrice)
          .toList();
    }
    if (maxPrice != null) {
      results = results
          .where((kost) => kost.pricePerMonth <= maxPrice)
          .toList();
    }

    // Apply rating filter
    if (minRating != null) {
      results = results.where((kost) => kost.rating >= minRating).toList();
    }

    // Apply facilities filter
    if (requiredFacilities != null && requiredFacilities.isNotEmpty) {
      results = results.where((kost) {
        return requiredFacilities.every(
          (facility) => kost.hasFacility(facility),
        );
      }).toList();
    }

    // Apply sorting
    return sortKost(results, sortBy, ascending: ascending);
  }
}
