/// ============================================================
/// app_router.dart — Named Route Definitions
/// ============================================================
/// Centralizes all route names and their corresponding screens.
/// Usage: Navigator.pushNamed(context, AppRouter.home)
/// ============================================================

import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/shop_detail_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/order_confirmation_screen.dart';
import '../screens/customer/order_history_screen.dart';
import '../screens/rider/rider_home_screen.dart';
import '../screens/customer/order_tracking_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/profile_screen.dart';

class AppRouter {
  /// ── Route Names ───────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String riderHome = '/rider-home';
  static const String shopDetail = '/shop-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderHistory = '/order-history';
  static const String orderTracking = '/order-tracking';
  static const String adminDashboard = '/admin-dashboard';
  static const String profile = '/profile';

  /// ── Route Map ─────────────────────────────────
  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (_) => const SplashScreen(),
      login: (_) => const LoginScreen(),
      otp: (_) => const OTPScreen(),
      profileSetup: (_) => const ProfileSetupScreen(),
      home: (_) => const HomeScreen(),
      riderHome: (_) => const RiderHomeScreen(),
      shopDetail: (_) => const ShopDetailScreen(),
      cart: (_) => const CartScreen(),
      checkout: (_) => const CheckoutScreen(),
      orderConfirmation: (_) => const OrderConfirmationScreen(),
      orderHistory: (_) => const OrderHistoryScreen(),
      adminDashboard: (_) => const AdminDashboard(),
      profile: (_) => const ProfileScreen(),
    };
  }

  /// ── onGenerateRoute (for screens needing arguments) ──
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case orderTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
