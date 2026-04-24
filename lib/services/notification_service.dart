/// ============================================================
/// notification_service.dart — Push Notifications (Milestone 3)
/// ============================================================
/// Manages Firebase Cloud Messaging (FCM):
///   - Request notification permissions
///   - Get & store FCM token in Firestore
///   - Handle foreground notifications
///   - Send local notifications on order status changes
///
/// Data Flow:
///   Order status changes → Firestore listener → FCM notification
/// ============================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ──────────────────────────────────────────────
  // Initialize FCM & request permissions
  /// ──────────────────────────────────────────────
  Future<void> initialize(String userId) async {
    // 1. Request notification permissions (iOS & Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(userId, token);
      }

      // 3. Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveFCMToken(userId, newToken);
      });

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Handle background/terminated messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  /// ──────────────────────────────────────────────
  // Save FCM token to Firestore user document
  /// ──────────────────────────────────────────────
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM Token saved for user: $userId');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// ──────────────────────────────────────────────
  // Handle foreground notifications
  /// ──────────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // The notification will be shown automatically on Android
    // For custom handling, use flutter_local_notifications package
  }

  /// ──────────────────────────────────────────────
  // Handle background/terminated notifications
  /// ──────────────────────────────────────────────
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message opened: ${message.notification?.title}');
    // Navigate to order tracking screen based on data payload
  }

  /// ──────────────────────────────────────────────
  // Get status change notification text
  /// ──────────────────────────────────────────────
  static Map<String, String> getStatusNotification(String status) {
    switch (status) {
      case 'accepted':
        return {
          'title': '🏍️ Rider Assigned!',
          'body': 'A delivery partner has accepted your order and is heading to the shop.',
        };
      case 'picked_up':
        return {
          'title': '📦 Order Picked Up!',
          'body': 'Your order has been picked up and is on the way to you.',
        };
      case 'delivered':
        return {
          'title': '✅ Order Delivered!',
          'body': 'Your order has been delivered successfully. Enjoy!',
        };
      default:
        return {
          'title': 'Order Update',
          'body': 'Your order status has been updated to: $status',
        };
    }
  }
}
