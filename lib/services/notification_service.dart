/// ============================================================
/// notification_service.dart — Local Push Notifications
/// ============================================================
/// Handles in-app local notifications for:
///   - Customer: Order status updates (accepted, picked up, delivered)
///   - Rider: New order available alerts
///
/// Uses flutter_local_notifications for system-level notifications
/// that appear even when the app is in background.
/// ============================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification plugin
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _isInitialized = true;

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Notifications for order status changes',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  // ── Customer Notifications ──────────────────────

  /// Notify customer when rider accepts their order
  Future<void> notifyOrderAccepted(String orderId) async {
    await showNotification(
      id: orderId.hashCode,
      title: '🎉 Order Accepted!',
      body: 'A rider has accepted your order and is heading to the shop.',
    );
  }

  /// Notify customer when rider picks up the order
  Future<void> notifyOrderPickedUp(String orderId) async {
    await showNotification(
      id: orderId.hashCode + 1,
      title: '📦 Order Picked Up!',
      body: 'Your order has been picked up and is on the way to you.',
    );
  }

  /// Notify customer when order is delivered
  Future<void> notifyOrderDelivered(String orderId) async {
    await showNotification(
      id: orderId.hashCode + 2,
      title: '✅ Order Delivered!',
      body: 'Your order has been delivered. Enjoy!',
    );
  }

  // ── Rider Notifications ─────────────────────────

  /// Notify rider when a new order is available
  Future<void> notifyNewOrderAvailable(int count) async {
    await showNotification(
      id: 9999,
      title: '🔔 New Order Available!',
      body: '$count order(s) waiting for pickup nearby.',
    );
  }
}
