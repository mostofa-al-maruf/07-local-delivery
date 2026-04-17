import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/demo_data.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';

class FirebaseSeeder {
  static Future<void> seedDemoData() async {
    try {
      if (kDebugMode) {
        print('SEEDER: Starting Demo Data Upload to Firestore...');
      }
      final firestore = FirebaseFirestore.instance;

      // Check if data already exists to save unnecessary writes
      final checkQuery = await firestore.collection('shops').limit(1).get();
      if (checkQuery.docs.isNotEmpty) {
        if (kDebugMode) {
          print('SEEDER: Data already exists in Firestore! Skipping upload.');
        }
        return;
      }

      // Seed Shops
      for (ShopModel shop in DemoData.allShops) {
        if (kDebugMode) {
          print('SEEDER: Uploading shop ${shop.shopId} - ${shop.shopName}...');
        }
        await firestore.collection('shops').doc(shop.shopId).set(shop.toFirestore());

        // Seed Products for this Shop
        List<ProductModel> products = DemoData.getProductsForShop(shop.shopId);
        for (ProductModel product in products) {
          await firestore
              .collection('shops')
              .doc(shop.shopId)
              .collection('products')
              .doc(product.productId)
              .set(product.toFirestore());
        }
      }

      if (kDebugMode) {
        print('SEEDER: Data upload completed successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SEEDER ERROR: Failed to upload data: $e');
      }
    }
  }
}
