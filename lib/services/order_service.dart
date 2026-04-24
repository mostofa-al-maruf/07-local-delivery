/// ============================================================
/// order_service.dart — Order Firestore Service
/// ============================================================
/// Handles order submission and retrieval:
///   - Submit a new order with items to Firestore
///   - Fetch order history for a customer
//
/// Data Flow (Order Submission):
///   CheckoutScreen → OrderProvider → OrderService.submitOrder()
///     → Firestore WriteBatch:
///         1. Write to /orders/{orderId}
///         2. Write each item to /orders/{orderId}/items/{itemId}
///     → Order placed with status: 'pending'
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';

class OrderService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// ──────────────────────────────────────────────
  // Submit a new order (with items as sub-collection)
  /// ──────────────────────────────────────────────
  // Creates the order document AND all item documents in a single
  // atomic batch write. This ensures either everything is written
  // or nothing is — no partial orders.
  Future<String> submitOrder(OrderModel order) async {
    // Use a Firestore batch for atomic writes
    final batch = _firestore.batch();

    // 1. Create the main order document
    final orderRef = _firestore.collection('orders').doc(order.orderId);
    batch.set(orderRef, order.toFirestore());

    // 2. Create each cart item as a sub-document under /orders/{id}/items/
    for (int i = 0; i < order.items.length; i++) {
      final itemRef = orderRef.collection('items').doc();
      batch.set(itemRef, order.items[i].toOrderItem());
    }

    // 3. Commit the batch — all-or-nothing
    await batch.commit();

    return order.orderId;
  }

  /// ──────────────────────────────────────────────
  // Fetch order history for a customer
  /// ──────────────────────────────────────────────
  // Returns all orders placed by a specific customer,
  // sorted by most recent first.
  Future<List<OrderModel>> fetchOrderHistory(String customerId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .get();

    var list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return list;
  }

  /// ──────────────────────────────────────────────
  // Fetch a single order with its items
  /// ──────────────────────────────────────────────
  // Returns an order document along with its items sub-collection.
  Future<OrderModel?> fetchOrderWithItems(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;

    final order = OrderModel.fromFirestore(doc);

    // Fetch items sub-collection
    final itemsSnapshot = await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .get();

    final items = itemsSnapshot.docs.map((itemDoc) {
      final data = itemDoc.data();
      return CartItem(
        productId: data['productId'] ?? '',
        shopId: order.shopId,
        shopName: order.shopName,
        productName: data['productName'] ?? '',
        unitPrice: (data['unitPrice'] ?? 0).toDouble(),
        imageUrl: data['imageUrl'] ?? '',
        unit: data['unit'] ?? 'piece',
        quantity: data['quantity'] ?? 1,
      );
    }).toList();

    // Return order with items populated
    return OrderModel(
      orderId: order.orderId,
      customerId: order.customerId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      shopId: order.shopId,
      shopName: order.shopName,
      orderType: order.orderType,
      status: order.status,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      platformFee: order.platformFee,
      totalAmount: order.totalAmount,
      paymentMethod: order.paymentMethod,
      deliveryAddress: order.deliveryAddress,
      customerNote: order.customerNote,
      items: items,
      placedAt: order.placedAt,
    );
  }

  /// ──────────────────────────────────────────────
  // Stream active orders (real-time updates)
  /// ──────────────────────────────────────────────
  // Returns a real-time stream of active orders for a customer.
  // Useful for the order tracking screen.
  Stream<List<OrderModel>> streamActiveOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .where('status', whereIn: ['pending', 'confirmed', 'assigned', 'picked_up'])
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
          return list;
        });
  }

  // ══════════════════════════════════════════════
  //  RIDER WORKFLOW METHODS (Milestone 3)
  // ══════════════════════════════════════════════

  /// ──────────────────────────────────────────────
  // Stream pending orders for riders to pick up
  /// ──────────────────────────────────────────────
  // Returns a real-time stream of orders with status 'pending'
  // that have not yet been assigned to any rider.
  Stream<List<OrderModel>> streamPendingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
          return list;
        });
  }

  /// ──────────────────────────────────────────────
  // Accept an order — assign rider to it
  /// ──────────────────────────────────────────────
  // Sets riderId, riderName, riderPhone and changes status to 'accepted'.
  Future<void> acceptOrder({
    required String orderId,
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ──────────────────────────────────────────────
  // Update order status (Accepted → Picked Up → Delivered)
  /// ──────────────────────────────────────────────
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
    };
    // Mark delivery timestamp when delivered
    if (newStatus == 'delivered') {
      updateData['deliveredAt'] = FieldValue.serverTimestamp();
      updateData['paymentStatus'] = 'paid';
    }
    await _firestore.collection('orders').doc(orderId).update(updateData);
  }

  /// ──────────────────────────────────────────────
  // Stream the rider's currently active order
  /// ──────────────────────────────────────────────
  // Returns a real-time stream of the single order assigned to this rider.
  Stream<OrderModel?> streamRiderActiveOrder(String riderId) {
    return _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', whereIn: ['accepted', 'picked_up'])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return OrderModel.fromFirestore(snapshot.docs.first);
        });
  }

  /// ──────────────────────────────────────────────
  // Stream a single order by ID (for customer tracking)
  /// ──────────────────────────────────────────────
  Stream<OrderModel?> streamOrderById(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return OrderModel.fromFirestore(doc);
        });
  }

  /// ──────────────────────────────────────────────
  // Fetch all orders (Admin Dashboard)
  /// ──────────────────────────────────────────────
  Stream<List<OrderModel>> streamAllOrders() {
    return _firestore
        .collection('orders')
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
          return list;
        });
  }
}
