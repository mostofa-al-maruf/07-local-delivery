/// ============================================================
/// cart_item_model.dart — Cart Item Data Model
/// ============================================================
/// Represents a single item in the user's shopping cart.
/// This is an in-memory model — not stored in Firestore until
/// the order is placed.
/// ============================================================

import 'product_model.dart';

class CartItem {
  final String productId;
  final String shopId;
  final String shopName;
  final String productName;
  final String imageUrl;
  final double unitPrice;    // Price per unit at time of adding
  final String unit;         // kg | piece | litre | pack
  int quantity;              // Mutable — can increase/decrease

  CartItem({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.productName,
    required this.unitPrice,
    this.imageUrl = '',
    this.unit = 'piece',
    this.quantity = 1,
  });

  // Total price for this line item
  double get totalPrice => unitPrice * quantity;

  // Create a CartItem from a ProductModel
  // This "snapshots" the product's current price into the cart
  factory CartItem.fromProduct(ProductModel product, String shopName) {
    return CartItem(
      productId: product.productId,
      shopId: product.shopId,
      shopName: shopName,
      productName: product.name,
      unitPrice: product.effectivePrice,
      imageUrl: product.imageUrl,
      unit: product.unit,
      quantity: 1,
    );
  }

  /// Convert CartItem → Map for Firestore order_items sub-collection
  Map<String, dynamic> toOrderItem() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'unit': unit,
      'imageUrl': imageUrl,
    };
  }
}
