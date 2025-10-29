import '../models/kost.dart';
import '../models/booking.dart';

class CartItem {
  final String id;
  final BaseKost kost;
  final RoomDetail? selectedRoom;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int duration;
  final String? notes;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.kost,
    this.selectedRoom,
    this.checkInDate,
    this.checkOutDate,
    this.duration = 1,
    this.notes,
    required this.addedAt,
  });

  double get totalPrice => kost.pricePerMonth * duration.toDouble();
  double get depositAmount => kost.pricePerMonth.toDouble();
  double get grandTotal => totalPrice + depositAmount;

  CartItem copyWith({
    String? id,
    BaseKost? kost,
    RoomDetail? selectedRoom,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? duration,
    String? notes,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      kost: kost ?? this.kost,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final Map<String, List<CartItem>> _userCarts = {}; // userId: [CartItem]

  // Get user cart
  List<CartItem> getUserCart(String userId) {
    return _userCarts[userId] ?? [];
  }

  // Add to cart
  CartItem addToCart({
    required String userId,
    required BaseKost kost,
    RoomDetail? selectedRoom,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int duration = 1,
    String? notes,
  }) {
    if (!_userCarts.containsKey(userId)) {
      _userCarts[userId] = [];
    }

    // Check if kost already in cart
    final existingIndex = _userCarts[userId]!.indexWhere(
      (item) => item.kost.id == kost.id,
    );

    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      kost: kost,
      selectedRoom: selectedRoom,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      duration: duration,
      notes: notes,
      addedAt: DateTime.now(),
    );

    if (existingIndex != -1) {
      // Update existing item
      _userCarts[userId]![existingIndex] = cartItem;
    } else {
      // Add new item
      _userCarts[userId]!.add(cartItem);
    }

    return cartItem;
  }

  // Remove from cart
  bool removeFromCart(String userId, String cartItemId) {
    final cart = _userCarts[userId];
    if (cart == null) return false;

    final index = cart.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return false;

    cart.removeAt(index);
    return true;
  }

  // Update cart item
  bool updateCartItem(String userId, String cartItemId, CartItem updatedItem) {
    final cart = _userCarts[userId];
    if (cart == null) return false;

    final index = cart.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return false;

    _userCarts[userId]![index] = updatedItem;
    return true;
  }

  // Clear cart
  void clearCart(String userId) {
    _userCarts[userId]?.clear();
  }

  // Get cart count
  int getCartCount(String userId) {
    return _userCarts[userId]?.length ?? 0;
  }

  // Get total price
  double getTotalPrice(String userId) {
    final cart = _userCarts[userId] ?? [];
    return cart.fold(0.0, (sum, item) => sum + item.grandTotal);
  }

  // Check if kost in cart
  bool isInCart(String userId, String kostId) {
    final cart = _userCarts[userId] ?? [];
    return cart.any((item) => item.kost.id == kostId);
  }

  // Get cart item by kost id
  CartItem? getCartItemByKostId(String userId, String kostId) {
    final cart = _userCarts[userId] ?? [];
    try {
      return cart.firstWhere((item) => item.kost.id == kostId);
    } catch (e) {
      return null;
    }
  }
}
