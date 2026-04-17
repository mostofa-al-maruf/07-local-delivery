/// ============================================================
/// shop_provider.dart — Shop Listing State Management
/// ============================================================
/// In DEMO MODE: Returns shops from DemoData.
/// In LIVE MODE: Fetches from Firestore via ShopService.
/// ============================================================

import 'package:flutter/material.dart';
import '../models/shop_model.dart';
import '../services/shop_service.dart';
import '../config/demo_data.dart';

class ShopProvider extends ChangeNotifier {
  final ShopService _shopService = ShopService();

  /// ── State Variables ───────────────────────────
  List<ShopModel> _shops = [];
  String _selectedCategory = 'all';
  bool _isLoading = false;
  String? _errorMessage;

  /// ── Category Definitions ──────────────────────
  static const List<Map<String, String>> categories = [
    {'key': 'all', 'label': 'All', 'icon': '🏪'},
    {'key': 'grocery', 'label': 'Grocery', 'icon': '🛒'},
    {'key': 'fish', 'label': 'Fish', 'icon': '🐟'},
    {'key': 'meat', 'label': 'Meat', 'icon': '🥩'},
    {'key': 'vegetables', 'label': 'Vegetables', 'icon': '🥬'},
    {'key': 'pharmacy', 'label': 'Pharmacy', 'icon': '💊'},
    {'key': 'parcel_pickup', 'label': 'Parcel', 'icon': '📦'},
  ];

  /// ── Getters ───────────────────────────────────
  List<ShopModel> get shops => _shops;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ──────────────────────────────────────────────
  /// Select category and fetch shops
  /// ──────────────────────────────────────────────
  Future<void> selectCategory(String category) async {
    _selectedCategory = category;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (DemoData.isDemoMode) {
        /// ── DEMO: Use mock data ──
        await Future.delayed(const Duration(milliseconds: 300));
        _shops = DemoData.getShopsByCategory(category);
      } else {
        /// ── LIVE: Fetch from Firestore ──
        if (category == 'all') {
          _shops = await _shopService.fetchAllShops();
        } else {
          _shops = await _shopService.fetchShopsByCategory(category);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load shops. Please try again.';
      _shops = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadShops() async {
    await selectCategory('all');
  }

  Future<void> searchShops(String query) async {
    if (query.trim().isEmpty) {
      await loadShops();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (DemoData.isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        _shops = DemoData.searchShops(query);
      } else {
        _shops = await _shopService.searchShops(query);
      }
    } catch (e) {
      _errorMessage = 'Search failed.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
