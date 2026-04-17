/// ============================================================
/// product_service.dart — Product Firestore Service
/// ============================================================
/// Fetches product data from the sub-collection:
///   /shops/{shopId}/products/{productId}
//
/// Data Flow:
///   ShopDetailScreen → ProductProvider → ProductService.fetchProducts()
///     → Firestore /shops/{shopId}/products (WHERE isAvailable == true)
///     → List<ProductModel> → displayed in ProductCard widgets
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// ──────────────────────────────────────────────
  // Fetch all available products for a shop
  /// ──────────────────────────────────────────────
  // Returns all products that are currently available in the given shop.
  // Products are stored as a sub-collection under the shop document.
  Future<List<ProductModel>> fetchProducts(String shopId) async {
    final snapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .get();

    var list = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc, shopId))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// ──────────────────────────────────────────────
  // Fetch products by sub-category within a shop
  /// ──────────────────────────────────────────────
  /// Returns products filtered by sub-category (e.g., "Fruits", "Dairy").
  Future<List<ProductModel>> fetchProductsByCategory(
      String shopId, String category) async {
    final snapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('category', isEqualTo: category)
        .get();

    var list = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc, shopId))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// ──────────────────────────────────────────────
  /// Get distinct product categories within a shop
  /// ──────────────────────────────────────────────
  /// Returns a list of unique sub-categories for product tab filtering.
  // Fetches all products and extracts unique category values.
  Future<List<String>> fetchProductCategories(String shopId) async {
    final snapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .get();

    final categories = snapshot.docs
        .map((doc) => (doc.data()['category'] ?? '') as String)
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }
}
