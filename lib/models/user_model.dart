/// ============================================================
/// user_model.dart — User Data Model
/// ============================================================
/// Represents a user (Customer or Delivery Partner).
/// Maps to Firestore collection: /users/{uid}
//
/// SCHEMA REFERENCE (Milestone 1 Schema Diagram):
///   uid (PK), phone, name, email, role (customer|rider|admin),
///   profileImageUrl, defaultLocation (geopoint), fcmToken,
///   isActive, createdAt, updatedAt
/// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;               // Firebase Auth UID (PK)
  final String phone;             // Verified phone number
  final String name;              // Display name
  final String email;             // Optional email
  final String role;              // 'customer' | 'rider' | 'admin'
  final String profileImageUrl;   // Profile photo URL
  final GeoPoint? defaultLocation;// Default location (geopoint)
  final String address;           // Human-readable default address
  final String fcmToken;          // Push notification token
  final bool isActive;            // Account active status
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.phone,
    this.name = '',
    this.email = '',
    this.role = 'customer',
    this.profileImageUrl = '',
    this.defaultLocation,
    this.address = '',
    this.fcmToken = '',
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert Firestore document → UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      profileImageUrl: data['profileImageUrl'] ?? '',
      defaultLocation: data['defaultLocation'] as GeoPoint?,
      address: data['address'] ?? '',
      fcmToken: data['fcmToken'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert UserModel → Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'defaultLocation': defaultLocation,
      'address': address,
      'fcmToken': fcmToken,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
