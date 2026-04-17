/// ============================================================
/// shop_model.dart — Shop Data Model
/// ============================================================
/// Represents a local shop/vendor.
/// Maps to Firestore collection: /shops/{shopId}
//
/// SCHEMA REFERENCE (Milestone 1 Schema Diagram):
///   shopId (PK), ownerName, shopName, phone,
///   category (grocery|fish|meat|vegetables|pharmacy|parcel_pickup),
///   location (geopoint), geoHash, status (pending|verified|suspended),
///   rating, totalOrders, commissionRate, isOpen,
///   operatingHours, verifiedBy
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String shopId;            // Document ID (PK)
  final String shopName;          // Shop display name
  final String ownerName;         // Owner's name
  final String phone;             // Contact number
  final String category;          // grocery | fish | meat | vegetables | pharmacy | parcel_pickup
  final GeoPoint? location;       // Shop coordinates (geopoint)
  final String geoHash;           // For geo-queries (GeoFlutterFire)
  final String status;            // pending | verified | suspended
  final double rating;            // Average rating (0.0 - 5.0)
  final int totalOrders;          // Lifetime order count
  final double commissionRate;    // Platform commission percentage
  final bool isOpen;              // Currently accepting orders
  final String operatingHours;    // e.g., "9:00 AM - 10:00 PM"
  final String verifiedBy;        // Admin UID who verified
  final String description;       // Shop description
  final String imageUrl;          // Shop banner image
  final String logoUrl;           // Shop logo
  final String addressText;       // Human-readable address

  ShopModel({
    required this.shopId,
    required this.shopName,
    this.ownerName = '',
    this.phone = '',
    required this.category,
    this.location,
    this.geoHash = '',
    this.status = 'verified',
    this.rating = 0.0,
    this.totalOrders = 0,
    this.commissionRate = 8.0,
    this.isOpen = true,
    this.operatingHours = '',
    this.verifiedBy = '',
    this.description = '',
    this.imageUrl = '',
    this.logoUrl = '',
    this.addressText = '',
  });

  /// Convert Firestore document → ShopModel
  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopModel(
      shopId: doc.id,
      shopName: data['shopName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      phone: data['phone'] ?? '',
      category: data['category'] ?? 'grocery',
      location: data['location'] as GeoPoint?,
      geoHash: data['geoHash'] ?? '',
      status: data['status'] ?? 'verified',
      rating: (data['rating'] ?? 0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      commissionRate: (data['commissionRate'] ?? 8).toDouble(),
      isOpen: data['isOpen'] ?? true,
      operatingHours: data['operatingHours'] ?? '',
      verifiedBy: data['verifiedBy'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      addressText: data['addressText'] ?? '',
    );
  }

  /// Convert ShopModel → Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'category': category,
      'location': location,
      'geoHash': geoHash,
      'status': status,
      'rating': rating,
      'totalOrders': totalOrders,
      'commissionRate': commissionRate,
      'isOpen': isOpen,
      'operatingHours': operatingHours,
      'verifiedBy': verifiedBy,
      'description': description,
      'imageUrl': imageUrl,
      'logoUrl': logoUrl,
      'addressText': addressText,
    };
  }

  /// Get the display icon for this shop's category
  String get categoryIcon {
    switch (category) {
      case 'grocery':
        return '🛒';
      case 'fish':
        return '🐟';
      case 'meat':
        return '🥩';
      case 'vegetables':
        return '🥬';
      case 'pharmacy':
        return '💊';
      case 'parcel_pickup':
        return '📦';
      default:
        return '🏪';
    }
  }
}
