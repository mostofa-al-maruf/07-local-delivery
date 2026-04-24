/// ============================================================
/// main.dart — App Entry Point
/// ============================================================
/// Initializes Firebase (if not in demo mode), registers all
/// Providers, and launches the app.
//
/// DEMO MODE: Set DemoData.isDemoMode = true to run the app
/// without Firebase. All data comes from demo_data.dart.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/demo_data.dart';
import 'providers/auth_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/product_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/seeder.dart';

import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';

import 'providers/rider_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ─────────────────────────────────────────────
  // Start in DEMO MODE by default (no Firebase needed).
  // Set to false and uncomment Firebase.initializeApp()
  // when you connect your Firebase project.
  /// ─────────────────────────────────────────────
  DemoData.isDemoMode = false;

  // Firebase is now configured!
  if (!DemoData.isDemoMode) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Seed Firestore with Demo Data (runs once to populate DB)
    await FirebaseSeeder.seedDemoData();

    // Initialize local notifications
    await NotificationService().initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RiderProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: '07 Local Delivery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.splash,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
