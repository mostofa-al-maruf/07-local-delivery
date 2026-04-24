/// ============================================================
/// rider_provider.dart — Rider State Management (Milestone 3)
/// ============================================================
/// Manages the delivery partner's workflow:
///   - Online/Offline toggle
///   - Real-time pending order stream from Firestore
///   - Accept order → Status progression → Delivery complete
///
/// Data Flow:
///   RiderHomeScreen → RiderProvider → OrderService
///     → Firestore real-time streams
/// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class RiderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  /// ── State Variables ───────────────────────────
  bool _isOnline = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Current order the rider is assigned to
  OrderModel? _activeOrder;

  // Pending orders available for pickup
  List<OrderModel> _pendingOrders = [];

  // Stream subscriptions (for cleanup)
  StreamSubscription? _pendingOrdersSub;
  StreamSubscription? _activeOrderSub;

  // Rider metrics (will be calculated from Firestore later)
  double _earningsToday = 0.0;
  int _totalDeliveries = 0;
  final double rating = 4.8;

  /// ── Getters ───────────────────────────────────
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OrderModel? get activeOrder => _activeOrder;
  List<OrderModel> get pendingOrders => _pendingOrders;
  bool get hasIncomingRequest => _pendingOrders.isNotEmpty && _activeOrder == null;
  bool get isOrderAccepted => _activeOrder != null;
  double get earningsToday => _earningsToday;
  int get totalDeliveries => _totalDeliveries;

  /// ── Status helpers ────────────────────────────
  String get currentStatusLabel {
    if (_activeOrder == null) return 'No active order';
    switch (_activeOrder!.status) {
      case 'accepted':
        return 'Head to shop for pickup';
      case 'picked_up':
        return 'Delivering to customer';
      default:
        return _activeOrder!.status;
    }
  }

  String get nextStatusAction {
    if (_activeOrder == null) return '';
    switch (_activeOrder!.status) {
      case 'accepted':
        return 'Confirm Pickup';
      case 'picked_up':
        return 'Mark as Delivered';
      default:
        return '';
    }
  }

  String? get nextStatus {
    if (_activeOrder == null) return null;
    switch (_activeOrder!.status) {
      case 'accepted':
        return 'picked_up';
      case 'picked_up':
        return 'delivered';
      default:
        return null;
    }
  }

  /// ──────────────────────────────────────────────
  // Toggle Online/Offline Status
  /// ──────────────────────────────────────────────
  void toggleOnlineStatus(bool value, String riderId) {
    _isOnline = value;
    notifyListeners();

    if (_isOnline) {
      _startListeningForOrders();
      _startListeningForActiveOrder(riderId);
    } else {
      _stopListening();
      _pendingOrders = [];
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  // Start listening for pending orders
  /// ──────────────────────────────────────────────
  void _startListeningForOrders() {
    _pendingOrdersSub?.cancel();
    _pendingOrdersSub = _orderService.streamPendingOrders().listen(
      (orders) {
        _pendingOrders = orders;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load orders: $e';
        notifyListeners();
      },
    );
  }

  /// ──────────────────────────────────────────────
  // Start listening for active order assigned to this rider
  /// ──────────────────────────────────────────────
  void _startListeningForActiveOrder(String riderId) {
    _activeOrderSub?.cancel();
    _activeOrderSub = _orderService.streamRiderActiveOrder(riderId).listen(
      (order) {
        _activeOrder = order;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to load active order: $e';
        notifyListeners();
      },
    );
  }

  /// ──────────────────────────────────────────────
  // Accept an order
  /// ──────────────────────────────────────────────
  Future<void> acceptOrder({
    required String orderId,
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.acceptOrder(
        orderId: orderId,
        riderId: riderId,
        riderName: riderName,
        riderPhone: riderPhone,
      );
      // The stream will automatically update _activeOrder
    } catch (e) {
      _errorMessage = 'Failed to accept order: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  // Progress to next order status
  /// ──────────────────────────────────────────────
  Future<void> progressOrderStatus() async {
    if (_activeOrder == null || nextStatus == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.updateOrderStatus(
        _activeOrder!.orderId,
        nextStatus!,
      );

      // If delivered, update local metrics
      if (nextStatus == 'delivered') {
        _totalDeliveries++;
        _earningsToday += _activeOrder!.deliveryFee;
        _activeOrder = null;
      }
      // The stream will automatically update for non-delivered statuses
    } catch (e) {
      _errorMessage = 'Failed to update order: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  // Skip/Reject a pending order (just remove from local list)
  /// ──────────────────────────────────────────────
  void skipOrder(String orderId) {
    _pendingOrders.removeWhere((o) => o.orderId == orderId);
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  // Clean up streams on dispose
  /// ──────────────────────────────────────────────
  void _stopListening() {
    _pendingOrdersSub?.cancel();
    _activeOrderSub?.cancel();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
