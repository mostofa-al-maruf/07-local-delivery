/// ============================================================
/// cart_provider.dart — Cart State Management
/// ============================================================
/// Manages the shopping cart — the CORE state of the app.
//
/// IMPORTANT RULE: Single-Shop Cart
///   A customer can only have items from ONE shop at a time.
///   Adding an item from a different shop clears the cart first
///   (with user confirmation).
//
/// Data Flow:
///   ProductCard "Add" button
///     → CartProvider.addItem(product, shopName)
///     → CartItem added to _items map
///     → notifyListeners()
///     → Cart badge updates, CartScreen updates
//
///   CartScreen "+/-" buttons
///     → CartProvider.updateQuantity(productId, newQty)
///     → _items[productId].quantity updated
///     → Subtotal recalculated automatically via getter
/// ============================================================

import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  /// ── State Variables ───────────────────────────
  // Using a Map for O(1) lookup by productId
  final Map<String, CartItem> _items = {};
  String? _currentShopId;    // Enforces single-shop rule
  String? _currentShopName;

  /// ── Getters ───────────────────────────────────
  Map<String, CartItem> get items => Map.unmodifiable(_items);
  List<CartItem> get itemsList => _items.values.toList();
  String? get currentShopId => _currentShopId;
  String? get currentShopName => _currentShopName;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;

  // Total number of individual units across all items
  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  // Subtotal — sum of (unitPrice × quantity) for all items
  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Delivery fee — base fee + per-km charge (simplified for now)
  double get deliveryFee => 30.0; // Fixed ৳30 for Phase 1

  // Platform service fee
  double get platformFee => 5.0;

  // Grand total
  double get totalAmount => subtotal + deliveryFee + platformFee;

  /// ──────────────────────────────────────────────
  // Check if adding from a different shop
  /// ──────────────────────────────────────────────
  bool isDifferentShop(String shopId) {
    return _currentShopId != null && _currentShopId != shopId && _items.isNotEmpty;
  }

  /// ──────────────────────────────────────────────
  // Add item to cart
  /// ──────────────────────────────────────────────
  // Adds a product to the cart. If the product is already in
  // the cart, increments its quantity by 1.
  void addItem(ProductModel product, String shopName) {
    // Set shop context on first item
    if (_items.isEmpty) {
      _currentShopId = product.shopId;
      _currentShopName = shopName;
    }

    if (_items.containsKey(product.productId)) {
      // Product already in cart — increment quantity
      _items[product.productId]!.quantity += 1;
    } else {
      // New product — create CartItem from ProductModel
      _items[product.productId] = CartItem.fromProduct(product, shopName);
    }

    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  // Remove item from cart
  /// ──────────────────────────────────────────────
  void removeItem(String productId) {
    _items.remove(productId);

    // If cart is now empty, clear shop context
    if (_items.isEmpty) {
      _currentShopId = null;
      _currentShopName = null;
    }

    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  // Update item quantity
  /// ──────────────────────────────────────────────
  // Sets the quantity of a specific item.
  // If quantity <= 0, removes the item entirely.
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.quantity = newQuantity;
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  // Increment / Decrement helpers
  /// ──────────────────────────────────────────────
  void incrementItem(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
      notifyListeners();
    }
  }

  void decrementItem(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity -= 1;
        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  /// ──────────────────────────────────────────────
  /// Get quantity of a specific product in cart
  /// ──────────────────────────────────────────────
  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  /// ──────────────────────────────────────────────
  // Check if product is in cart
  /// ──────────────────────────────────────────────
  bool isInCart(String productId) => _items.containsKey(productId);

  /// ──────────────────────────────────────────────
  // Clear entire cart
  /// ──────────────────────────────────────────────
  void clearCart() {
    _items.clear();
    _currentShopId = null;
    _currentShopName = null;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  // Switch shop (clear cart and add new item)
  /// ──────────────────────────────────────────────
  // Called when user confirms switching shops.
  // Clears existing cart and adds the new product.
  void switchShopAndAdd(ProductModel product, String shopName) {
    clearCart();
    addItem(product, shopName);
  }
}
