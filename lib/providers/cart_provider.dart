import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Cart Provider with Firestore Backend
/// Manages shopping cart with real-time synchronization
class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get total number of items in cart
  int get itemCount => _cartItems.length;

  /// Get total quantity of all items
  int get totalQuantity => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Calculate subtotal (sum of all item prices)
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Calculate total price (same as subtotal, no additional fees)
  double get total => subtotal;

  /// Check if product is in cart
  bool isInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  /// Get quantity of specific product in cart
  int getItemQuantity(String productId) {
    final item = _cartItems.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        id: '',
        userId: '',
        productId: '',
        productName: '',
        productImage: '',
        price: 0,
        unit: '',
        quantity: 0,
        farmerId: '',
        farmerName: '',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  /// Load cart items from Firestore
  Future<void> loadCart() async {
    if (_userId == null) {
      if (kDebugMode) {
        debugPrint('❌ Cannot load cart: User not authenticated');
      }
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('🛒 Loading cart for user: $_userId');
      }

      final querySnapshot = await _firestore
          .collection('cart_items')
          .where('user_id', isEqualTo: _userId)
          .orderBy('added_at', descending: true)
          .get();

      _cartItems = querySnapshot.docs
          .map((doc) => CartItem.fromFirestore(doc.data(), doc.id))
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Cart loaded: ${_cartItems.length} items');
      }
    } catch (e) {
      _error = 'Failed to load cart: $e';
      if (kDebugMode) {
        debugPrint('❌ Error loading cart: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add product to cart
  Future<void> addItem(
    Product product, {
    int quantity = 1,
    String? farmerId,
    String? farmerName,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (kDebugMode) {
        debugPrint('➕ Adding to cart: ${product.name} (qty: $quantity)');
      }

      // Check if product already in cart
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingItemIndex >= 0) {
        // Update existing item quantity
        final existingItem = _cartItems[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;
        
        await _firestore
            .collection('cart_items')
            .doc(existingItem.id)
            .update({
          'quantity': newQuantity,
          'updated_at': FieldValue.serverTimestamp(),
        });

        _cartItems[existingItemIndex] = existingItem.copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );
      } else {
        // Add new item to cart
        final cartItem = CartItem(
          id: '', // Will be set by Firestore
          userId: _userId!,
          productId: product.id,
          productName: product.name,
          productImage: product.images.isNotEmpty ? product.images[0] : '',
          price: product.price,
          unit: product.unit,
          quantity: quantity,
          farmerId: farmerId ?? product.farmId,
          farmerName: farmerName ?? 'Unknown Farmer',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final docRef = await _firestore
            .collection('cart_items')
            .add(cartItem.toFirestore());

        _cartItems.insert(0, cartItem.copyWith(id: docRef.id));
      }

      if (kDebugMode) {
        debugPrint('✅ Cart updated: ${_cartItems.length} items');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding to cart: $e');
      }
      rethrow;
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        await removeItem(cartItemId);
        return;
      }

      if (kDebugMode) {
        debugPrint('🔄 Updating cart item quantity: $cartItemId = $quantity');
      }

      await _firestore.collection('cart_items').doc(cartItemId).update({
        'quantity': quantity,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final itemIndex = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (itemIndex >= 0) {
        _cartItems[itemIndex] = _cartItems[itemIndex].copyWith(
          quantity: quantity,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating quantity: $e');
      }
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String cartItemId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (kDebugMode) {
        debugPrint('🗑️ Removing cart item: $cartItemId');
      }

      await _firestore.collection('cart_items').doc(cartItemId).delete();

      _cartItems.removeWhere((item) => item.id == cartItemId);

      if (kDebugMode) {
        debugPrint('✅ Item removed. Cart has ${_cartItems.length} items');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing item: $e');
      }
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clear() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      if (kDebugMode) {
        debugPrint('🧹 Clearing cart...');
      }

      // Delete all cart items for this user
      final querySnapshot = await _firestore
          .collection('cart_items')
          .where('user_id', isEqualTo: _userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _cartItems.clear();

      if (kDebugMode) {
        debugPrint('✅ Cart cleared');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing cart: $e');
      }
      rethrow;
    }
  }

  /// Group cart items by farmer
  Map<String, List<CartItem>> groupByFarmer() {
    final Map<String, List<CartItem>> grouped = {};
    
    for (var item in _cartItems) {
      if (!grouped.containsKey(item.farmerId)) {
        grouped[item.farmerId] = [];
      }
      grouped[item.farmerId]!.add(item);
    }
    
    return grouped;
  }

  /// Calculate subtotal for specific farmer
  double getSubtotalForFarmer(String farmerId) {
    return _cartItems
        .where((item) => item.farmerId == farmerId)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}
