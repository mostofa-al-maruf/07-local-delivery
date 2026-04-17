/// ============================================================
/// order_model.dart — Order Data Model
/// ============================================================
/// Represents a placed order.
/// Maps to Firestore collection: /orders/{orderId}
//
/// SCHEMA REFERENCE (Milestone 1 Schema Diagram):
///   orderId (PK), customerId (FK), shopId (FK), riderId (FK),
///   orderType, status (pending|confirmed|assigned|picked_up|
///   in_transit|delivered|cancelled), subtotal, deliveryFee,
///   platformFee, totalAmount, commissionAmount, paymentMethod,
///   paymentStatus, pickupLocation, dropoffLocation,
///   estimatedDistance, placedAt, deliveredAt
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String orderId;           // Unique order ID (PK)
  final String customerId;        // User UID (FK → users)
  final String customerName;
  final String customerPhone;
  final String shopId;            // Shop ID (FK → shops)
  final String shopName;
  final String? riderId;          // Rider ID (FK → delivery_partners) — null until assigned
  final String orderType;         // grocery | fish | meat | vegetables | pharmacy
  final String status;            // pending | confirmed | assigned | picked_up | in_transit | delivered | cancelled
  final double subtotal;          // Sum of all item prices
  final double deliveryFee;       // Distance-based delivery charge
  final double platformFee;       // Platform service fee
  final double totalAmount;       // subtotal + deliveryFee + platformFee
  final double commissionAmount;  // Platform commission from shop
  final String paymentMethod;     // 'cod' (Cash on Delivery) for Phase 1
  final String paymentStatus;     // 'pending' | 'paid' | 'refunded'
  final GeoPoint? pickupLocation; // Shop coordinates
  final GeoPoint? dropoffLocation;// Customer coordinates
  final String deliveryAddress;   // Human-readable delivery address
  final double estimatedDistance; // Distance in km
  final String customerNote;      // Special instructions
  final List<CartItem> items;     // Order line items
  final DateTime placedAt;
  final DateTime? deliveredAt;    // Set when status changes to 'delivered'

  OrderModel({
    required this.orderId,
    required this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    required this.shopId,
    required this.shopName,
    this.riderId,
    required this.orderType,
    this.status = 'pending',
    required this.subtotal,
    required this.deliveryFee,
    this.platformFee = 5.0,
    required this.totalAmount,
    this.commissionAmount = 0.0,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.pickupLocation,
    this.dropoffLocation,
    required this.deliveryAddress,
    this.estimatedDistance = 0.0,
    this.customerNote = '',
    required this.items,
    DateTime? placedAt,
    this.deliveredAt,
  }) : placedAt = placedAt ?? DateTime.now();

  /// Convert OrderModel → Firestore document Map
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shopId': shopId,
      'shopName': shopName,
      'riderId': riderId,
      'orderType': orderType,
      'status': status,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'platformFee': platformFee,
      'totalAmount': totalAmount,
      'commissionAmount': commissionAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'deliveryAddress': deliveryAddress,
      'estimatedDistance': estimatedDistance,
      'customerNote': customerNote,
      'placedAt': Timestamp.fromDate(placedAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  /// Convert Firestore document → OrderModel (without items sub-collection)
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      orderId: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      riderId: data['riderId'],
      orderType: data['orderType'] ?? '',
      status: data['status'] ?? 'pending',
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 5).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      commissionAmount: (data['commissionAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cod',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      pickupLocation: data['pickupLocation'] as GeoPoint?,
      dropoffLocation: data['dropoffLocation'] as GeoPoint?,
      deliveryAddress: data['deliveryAddress'] ?? '',
      estimatedDistance: (data['estimatedDistance'] ?? 0).toDouble(),
      customerNote: data['customerNote'] ?? '',
      items: [], // Items loaded separately from sub-collection
      placedAt: (data['placedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }
}
