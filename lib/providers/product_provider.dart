/// ============================================================
/// product_provider.dart — Product Listing State Management
/// ============================================================
/// In DEMO MODE: Returns products from DemoData.
/// In LIVE MODE: Fetches from Firestore via ProductService.
/// ============================================================

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../config/demo_data.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  /// ── State Variables ───────────────────────────
  List<ProductModel> _allProducts = [];
  List<ProductModel> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  /// ── Getters ───────────────────────────────────
  List<ProductModel> get products => _products;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ──────────────────────────────────────────────
  /// Load all products for a shop
  /// ──────────────────────────────────────────────
  Future<void> loadProducts(String shopId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedCategory = 'All';
    notifyListeners();

    try {
      if (DemoData.isDemoMode) {
        /// ── DEMO: Use mock data ──
        await Future.delayed(const Duration(milliseconds: 300));
        _allProducts = DemoData.getProductsForShop(shopId);
        _categories = DemoData.getProductCategories(shopId);
      } else {
        /// ── LIVE: Fetch from Firestore ──
        _allProducts = await _productService.fetchProducts(shopId);
        _categories = ['All'];
        final uniqueCats = _allProducts
            .map((p) => p.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        uniqueCats.sort();
        _categories.addAll(uniqueCats);
      }
      _products = List.from(_allProducts);
    } catch (e) {
      _errorMessage = 'Failed to load products.';
      _allProducts = [];
      _products = [];
      _categories = ['All'];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  /// Filter by sub-category
  /// ──────────────────────────────────────────────
  void selectCategory(String category) {
    _selectedCategory = category;
    if (category == 'All') {
      _products = List.from(_allProducts);
    } else {
      _products = _allProducts.where((p) => p.category == category).toList();
    }
    notifyListeners();
  }

  void clearProducts() {
    _allProducts = [];
    _products = [];
    _categories = ['All'];
    _selectedCategory = 'All';
    notifyListeners();
  }
}
