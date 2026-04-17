/// ============================================================
/// shop_service.dart — Shop Firestore Service
/// ============================================================
/// Fetches shop data from Firestore:
///   - All verified & open shops
///   - Shops filtered by category
//
/// Data Flow:
///   HomeScreen → ShopProvider → ShopService.fetchShopsByCategory()
///     → Firestore /shops (WHERE category == X AND isOpen == true)
///     → List<ShopModel> → displayed in ShopCard widgets
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';

class ShopService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Reference to the shops collection
  CollectionReference get _shopsRef => _firestore.collection('shops');

  /// ──────────────────────────────────────────────
  // Fetch all verified, open shops
  /// ──────────────────────────────────────────────
  // Returns all shops that are verified and currently open.
  // Used when "All" category tab is selected.
  Future<List<ShopModel>> fetchAllShops() async {
    final snapshot = await _shopsRef
        .where('status', isEqualTo: 'verified')
        .where('isOpen', isEqualTo: true)
        .get();

    var list = snapshot.docs.map((doc) => ShopModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.rating.compareTo(a.rating)); // Sort locally instead
    return list;
  }

  /// ──────────────────────────────────────────────
  // Fetch shops by category
  /// ──────────────────────────────────────────────
  // Returns shops of a specific category (e.g., 'grocery', 'fish').
  // Firestore Query: WHERE category == X AND status == 'verified' AND isOpen == true
  Future<List<ShopModel>> fetchShopsByCategory(String category) async {
    final snapshot = await _shopsRef
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'verified')
        .where('isOpen', isEqualTo: true)
        .get();

    var list = snapshot.docs.map((doc) => ShopModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.rating.compareTo(a.rating)); // Sort locally instead
    return list;
  }

  /// ──────────────────────────────────────────────
  // Fetch a single shop by ID
  /// ──────────────────────────────────────────────
  // Returns a single shop document by its ID.
  // Used when navigating to shop detail screen.
  Future<ShopModel?> fetchShopById(String shopId) async {
    final doc = await _shopsRef.doc(shopId).get();
    if (doc.exists) {
      return ShopModel.fromFirestore(doc);
    }
    return null;
  }

  /// ──────────────────────────────────────────────
  /// Search shops by name
  /// ──────────────────────────────────────────────
  /// Simple search — fetches all shops and filters client-side.
  /// For production, consider Algolia or Firestore full-text search.
  Future<List<ShopModel>> searchShops(String query) async {
    final allShops = await fetchAllShops();
    final lowerQuery = query.toLowerCase();
    return allShops
        .where((shop) =>
            shop.shopName.toLowerCase().contains(lowerQuery) ||
            shop.category.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
