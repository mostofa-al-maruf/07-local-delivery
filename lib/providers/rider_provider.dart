/// ============================================================
/// rider_provider.dart — Rider State Management (Milestone 3)
/// ============================================================
/// Manages the delivery partner's workflow:
///   - Online/Offline toggle
///   - Real-time pending order stream from Firestore
///   - Accept order → Status progression → Delivery complete
///   - Persistent delivery stats in Firestore
///
/// Data Flow:
///   RiderHomeScreen → RiderProvider → OrderService
///     → Firestore real-time streams
/// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class RiderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ── State Variables ───────────────────────────
  bool _isOnline = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _riderId;

  // Current order the rider is assigned to
  OrderModel? _activeOrder;

  // Pending orders available for pickup
  List<OrderModel> _pendingOrders = [];

  // Stream subscriptions (for cleanup)
  StreamSubscription? _pendingOrdersSub;
  StreamSubscription? _activeOrderSub;

  // Rider metrics (persisted in Firestore)
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
  // Load rider stats from Firestore (called on go online)
  /// ──────────────────────────────────────────────
  Future<void> _loadRiderStats(String riderId) async {
    try {
      final doc = await _firestore.collection('users').doc(riderId).get();
      if (doc.exists) {
        _totalDeliveries = doc.data()?['totalDeliveries'] ?? 0;
        _earningsToday = (doc.data()?['totalEarnings'] ?? 0).toDouble();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// ──────────────────────────────────────────────
  // Save rider stats to Firestore
  /// ──────────────────────────────────────────────
  Future<void> _saveRiderStats() async {
    if (_riderId == null) return;
    try {
      await _firestore.collection('users').doc(_riderId).update({
        'totalDeliveries': _totalDeliveries,
        'totalEarnings': _earningsToday,
      });
    } catch (_) {}
  }

  /// ──────────────────────────────────────────────
  // Toggle Online/Offline Status
  /// ──────────────────────────────────────────────
  void toggleOnlineStatus(bool value, String riderId) {
    _isOnline = value;
    _riderId = riderId;
    notifyListeners();

    if (_isOnline) {
      _loadRiderStats(riderId);
      _startListeningForOrders();
      _startListeningForActiveOrder(riderId);
      _locationService.startTracking(riderId); // Start GPS tracking
    } else {
      _stopListening();
      _locationService.stopTracking(); // Stop GPS tracking
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
        // Trigger notification if there are new orders and rider is not busy
        if (orders.length > _pendingOrders.length && _activeOrder == null) {
          NotificationService().notifyNewOrderAvailable(orders.length);
        }
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

    // Save values BEFORE async call (stream may null _activeOrder after update)
    final targetStatus = nextStatus!;
    final orderId = _activeOrder!.orderId;
    final fee = _activeOrder!.deliveryFee;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.updateOrderStatus(orderId, targetStatus);

      // If delivered, update local metrics and save to Firestore
      if (targetStatus == 'delivered') {
        _totalDeliveries++;
        _earningsToday += fee;
        _activeOrder = null;
        await _saveRiderStats(); // Persist to Firestore!
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
