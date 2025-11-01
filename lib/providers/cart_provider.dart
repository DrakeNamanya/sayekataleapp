import 'package:flutter/material.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => subtotal > 0 ? 5000.0 : 0.0; // UGX 5000 delivery fee

  double get serviceFee => subtotal * 0.05; // 5% service fee

  double get total => subtotal + deliveryFee + serviceFee;

  void addItem(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(
        product: product,
        quantity: quantity,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity > 0) {
        _items[productId]!.quantity = quantity;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }
  
  /// Get quantity of a specific product in cart
  int getItemQuantity(String productId) {
    return _items.containsKey(productId) ? _items[productId]!.quantity : 0;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<CartItem> get cartItems => _items.values.toList();
}
