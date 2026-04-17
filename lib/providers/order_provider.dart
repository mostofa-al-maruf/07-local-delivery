/// ============================================================
/// order_provider.dart — Order State Management
/// ============================================================
/// In DEMO MODE: Stores orders in-memory (no Firestore).
/// In LIVE MODE: Submits to Firestore via OrderService.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/order_service.dart';
import '../config/demo_data.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final Uuid _uuid = const Uuid();

  /// ── State Variables ───────────────────────────
  List<OrderModel> _orders = [];
  OrderModel? _lastPlacedOrder;
  bool _isLoading = false;
  String? _errorMessage;

  /// ── Getters ───────────────────────────────────
  List<OrderModel> get orders => _orders;
  OrderModel? get lastPlacedOrder => _lastPlacedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ──────────────────────────────────────────────
  // Place a new order
  /// ──────────────────────────────────────────────
  Future<String?> placeOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String shopId,
    required String shopName,
    required String orderType,
    required double subtotal,
    required double deliveryFee,
    required double platformFee,
    required String deliveryAddress,
    required List<CartItem> items,
    String customerNote = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderId = _uuid.v4().substring(0, 8).toUpperCase();

      final order = OrderModel(
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        shopId: shopId,
        shopName: shopName,
        orderType: orderType,
        status: 'pending',
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        platformFee: platformFee,
        totalAmount: subtotal + deliveryFee + platformFee,
        paymentMethod: 'cod',
        deliveryAddress: deliveryAddress,
        customerNote: customerNote,
        items: items,
      );

      if (DemoData.isDemoMode) {
        /// ── DEMO: Store order in-memory ──
        await Future.delayed(const Duration(seconds: 1));
        _orders.insert(0, order);
      } else {
        /// ── LIVE: Submit to Firestore ──
        await _orderService.submitOrder(order);
      }

      _lastPlacedOrder = order;
      _isLoading = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _errorMessage = 'Failed to place order. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// ──────────────────────────────────────────────
  /// Load order history
  /// ──────────────────────────────────────────────
  Future<void> loadOrderHistory(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (DemoData.isDemoMode) {
        /// ── DEMO: Return in-memory orders ──
        await Future.delayed(const Duration(milliseconds: 300));
        // _orders already contains demo orders placed this session
      } else {
        /// ── LIVE: Fetch from Firestore ──
        _orders = await _orderService.fetchOrderHistory(customerId);
      }
    } catch (e) {
      _errorMessage = 'Failed to load orders.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
