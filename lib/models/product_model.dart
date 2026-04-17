/// ============================================================
/// product_model.dart — Product Data Model
/// ============================================================
/// Represents a product within a shop.
/// Maps to Firestore sub-collection: /shops/{shopId}/products/{productId}
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String shopId;       // Parent shop reference
  final String name;
  final String description;
  final String category;     // Sub-category within the shop (e.g., "Fruits", "Dairy")
  final double price;        // Unit price in BDT
  final double discountPrice; // Sale price (0 if no discount)
  final String unit;         // kg | piece | litre | pack
  final int stockQuantity;
  final bool isAvailable;
  final String imageUrl;

  ProductModel({
    required this.productId,
    required this.shopId,
    required this.name,
    this.description = '',
    this.category = '',
    required this.price,
    this.discountPrice = 0,
    this.unit = 'piece',
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.imageUrl = '',
  });

  // The effective price — use discount if available, else regular price
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;

  // Whether this product has an active discount
  bool get hasDiscount => discountPrice > 0 && discountPrice < price;

  // Discount percentage for display
  int get discountPercent =>
      hasDiscount ? ((1 - discountPrice / price) * 100).round() : 0;

  /// Convert Firestore document → ProductModel
  factory ProductModel.fromFirestore(DocumentSnapshot doc, String shopId) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: doc.id,
      shopId: shopId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      discountPrice: (data['discountPrice'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'piece',
      stockQuantity: data['stockQuantity'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  /// Convert ProductModel → Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'shopId': shopId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'discountPrice': discountPrice,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
    };
  }
}
