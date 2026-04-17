/// ============================================================
/// demo_data.dart — Mock Data for Demo Mode
/// ============================================================
/// Contains all sample data for demonstrating the app
/// without a Firebase connection. Includes:
///   - Sample user profile
///   - 8 shops across all 6 categories
///   - 20+ products with realistic BDT prices
//
/// Usage: When demo mode is active, providers use this data
///        instead of calling Firestore.
/// ============================================================

import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';

class DemoData {
  // Global flag — when true, all services return mock data
  static bool isDemoMode = false;

  /// ── Demo User ─────────────────────────────────
  static UserModel get demoUser => UserModel(
        uid: 'demo_user_001',
        phone: '+8801712345678',
        name: 'Rahim Hasan',
        role: 'customer',
        address: 'House 12, Road 5, Banani, Dhaka-1213',
      );

  /// ── Demo Shops (8 shops across 6 categories) ──
  static List<ShopModel> get allShops => [
        ShopModel(
          shopId: 'shop_001',
          shopName: 'FreshMart Grocery',
          ownerName: 'Karim Uddin',
          phone: '+8801700000001',
          category: 'grocery',
          description: 'Fresh groceries & daily essentials',
          addressText: 'Road 11, Banani, Dhaka',
          rating: 4.5,
          totalOrders: 234,
          isOpen: true,
          commissionRate: 8.0,
          operatingHours: '8:00 AM - 10:00 PM',
        ),
        ShopModel(
          shopId: 'shop_002',
          shopName: 'Sagar Fish Corner',
          ownerName: 'Abdul Matin',
          phone: '+8801700000002',
          category: 'fish',
          description: 'Fresh river & sea fish daily',
          addressText: 'Gulshan 2 Circle, Dhaka',
          rating: 4.3,
          totalOrders: 156,
          isOpen: true,
          commissionRate: 10.0,
          operatingHours: '6:00 AM - 8:00 PM',
        ),
        ShopModel(
          shopId: 'shop_003',
          shopName: 'Royal Meat House',
          ownerName: 'Jamal Hossain',
          phone: '+8801700000003',
          category: 'meat',
          description: 'Premium halal meat & poultry',
          addressText: 'Mohakhali, Dhaka',
          rating: 4.7,
          totalOrders: 312,
          isOpen: true,
          commissionRate: 10.0,
          operatingHours: '7:00 AM - 9:00 PM',
        ),
        ShopModel(
          shopId: 'shop_004',
          shopName: 'Green Valley Vegetables',
          ownerName: 'Rafiq Ahmed',
          phone: '+8801700000004',
          category: 'vegetables',
          description: 'Organic & fresh vegetables',
          addressText: 'Baridhara, Dhaka',
          rating: 4.1,
          totalOrders: 189,
          isOpen: true,
          commissionRate: 8.0,
          operatingHours: '6:00 AM - 9:00 PM',
        ),
        ShopModel(
          shopId: 'shop_005',
          shopName: 'MediCare Pharmacy',
          ownerName: 'Dr. Nasir',
          phone: '+8801700000005',
          category: 'pharmacy',
          description: 'Medicines, health & personal care',
          addressText: 'Uttara Sector 7, Dhaka',
          rating: 4.6,
          totalOrders: 445,
          isOpen: true,
          commissionRate: 5.0,
          operatingHours: '8:00 AM - 11:00 PM',
        ),
        ShopModel(
          shopId: 'shop_006',
          shopName: 'QuickSend Parcel',
          ownerName: 'Sohel Rana',
          phone: '+8801700000006',
          category: 'parcel_pickup',
          description: 'Fast & reliable parcel delivery',
          addressText: 'Mirpur 10, Dhaka',
          rating: 4.2,
          totalOrders: 678,
          isOpen: true,
          commissionRate: 0.0,
          operatingHours: '9:00 AM - 8:00 PM',
        ),
        ShopModel(
          shopId: 'shop_007',
          shopName: 'Daily Needs Store',
          ownerName: 'Habib Rahman',
          phone: '+8801700000007',
          category: 'grocery',
          description: 'Your everyday grocery store',
          addressText: 'Dhanmondi 27, Dhaka',
          rating: 4.0,
          totalOrders: 98,
          isOpen: true,
          commissionRate: 8.0,
          operatingHours: '7:00 AM - 10:00 PM',
        ),
        ShopModel(
          shopId: 'shop_008',
          shopName: 'Amin Vegetables',
          ownerName: 'Amin Khan',
          phone: '+8801700000008',
          category: 'vegetables',
          description: 'Fresh from the farm daily',
          addressText: 'Bashundhara R/A, Dhaka',
          rating: 3.9,
          totalOrders: 67,
          isOpen: false, // Closed shop for demo
          commissionRate: 8.0,
          operatingHours: '6:00 AM - 8:00 PM',
        ),
      ];

  /// Get shops filtered by category
  static List<ShopModel> getShopsByCategory(String category) {
    if (category == 'all') return allShops;
    return allShops.where((s) => s.category == category).toList();
  }

  /// ── Demo Products (per shop) ──────────────────
  static Map<String, List<ProductModel>> get allProducts => {
        /// ── FreshMart Grocery Products ──
        'shop_001': [
          ProductModel(productId: 'p001', shopId: 'shop_001', name: 'Miniket Rice (5kg)', category: 'Rice & Grains', price: 420, unit: 'bag', stockQuantity: 25),
          ProductModel(productId: 'p002', shopId: 'shop_001', name: 'Soybean Oil (5L)', category: 'Oil & Ghee', price: 890, unit: 'bottle', stockQuantity: 15),
          ProductModel(productId: 'p003', shopId: 'shop_001', name: 'Banana (12pc)', category: 'Fruits', price: 60, unit: 'dozen', stockQuantity: 40),
          ProductModel(productId: 'p004', shopId: 'shop_001', name: 'Aarong Milk (1L)', category: 'Dairy', price: 95, unit: 'pack', stockQuantity: 30),
          ProductModel(productId: 'p005', shopId: 'shop_001', name: 'Pran Mango Juice (1L)', category: 'Beverages', price: 120, unit: 'pack', stockQuantity: 20),
          ProductModel(productId: 'p006', shopId: 'shop_001', name: 'Red Lentil / Masoor Dal (1kg)', category: 'Rice & Grains', price: 145, unit: 'kg', stockQuantity: 35),
          ProductModel(productId: 'p007', shopId: 'shop_001', name: 'Sugar (1kg)', category: 'Rice & Grains', price: 130, unit: 'kg', stockQuantity: 50),
          ProductModel(productId: 'p008', shopId: 'shop_001', name: 'Egg (12pc)', category: 'Dairy', price: 180, discountPrice: 155, unit: 'dozen', stockQuantity: 20),
          ProductModel(productId: 'p009', shopId: 'shop_001', name: 'Radhuni Mixed Spice', category: 'Spices', price: 55, unit: 'pack', stockQuantity: 30),
          ProductModel(productId: 'p010', shopId: 'shop_001', name: 'Maggi Noodles (8 pack)', category: 'Snacks', price: 160, discountPrice: 140, unit: 'pack', stockQuantity: 25),
        ],

        /// ── Sagar Fish Corner Products ──
        'shop_002': [
          ProductModel(productId: 'p011', shopId: 'shop_002', name: 'Hilsa / Ilish (1kg)', category: 'River Fish', price: 1200, unit: 'kg', stockQuantity: 10),
          ProductModel(productId: 'p012', shopId: 'shop_002', name: 'Rui Fish (1kg)', category: 'River Fish', price: 350, unit: 'kg', stockQuantity: 15),
          ProductModel(productId: 'p013', shopId: 'shop_002', name: 'Katla Fish (1kg)', category: 'River Fish', price: 380, unit: 'kg', stockQuantity: 12),
          ProductModel(productId: 'p014', shopId: 'shop_002', name: 'Shrimp / Chingri (500g)', category: 'Sea Fish', price: 550, unit: 'pack', stockQuantity: 8),
          ProductModel(productId: 'p015', shopId: 'shop_002', name: 'Pangas Fish (1kg)', category: 'River Fish', price: 220, unit: 'kg', stockQuantity: 20),
        ],

        /// ── Royal Meat House Products ──
        'shop_003': [
          ProductModel(productId: 'p016', shopId: 'shop_003', name: 'Beef (1kg)', category: 'Beef', price: 700, unit: 'kg', stockQuantity: 15),
          ProductModel(productId: 'p017', shopId: 'shop_003', name: 'Chicken Breast (1kg)', category: 'Chicken', price: 320, unit: 'kg', stockQuantity: 20),
          ProductModel(productId: 'p018', shopId: 'shop_003', name: 'Whole Chicken (1.2kg)', category: 'Chicken', price: 380, discountPrice: 340, unit: 'piece', stockQuantity: 10),
          ProductModel(productId: 'p019', shopId: 'shop_003', name: 'Mutton / Khashi (1kg)', category: 'Mutton', price: 1100, unit: 'kg', stockQuantity: 8),
          ProductModel(productId: 'p020', shopId: 'shop_003', name: 'Chicken Wings (500g)', category: 'Chicken', price: 170, unit: 'pack', stockQuantity: 18),
        ],

        /// ── Green Valley Vegetables ──
        'shop_004': [
          ProductModel(productId: 'p021', shopId: 'shop_004', name: 'Potato / Alu (1kg)', category: 'Root', price: 40, unit: 'kg', stockQuantity: 50),
          ProductModel(productId: 'p022', shopId: 'shop_004', name: 'Onion / Peyaj (1kg)', category: 'Root', price: 65, unit: 'kg', stockQuantity: 40),
          ProductModel(productId: 'p023', shopId: 'shop_004', name: 'Tomato (1kg)', category: 'Vegetable', price: 80, unit: 'kg', stockQuantity: 30),
          ProductModel(productId: 'p024', shopId: 'shop_004', name: 'Green Chili (250g)', category: 'Spice Veg', price: 25, unit: 'pack', stockQuantity: 35),
          ProductModel(productId: 'p025', shopId: 'shop_004', name: 'Cauliflower (1pc)', category: 'Vegetable', price: 45, unit: 'piece', stockQuantity: 20),
          ProductModel(productId: 'p026', shopId: 'shop_004', name: 'Spinach / Palong Shak', category: 'Leafy', price: 15, unit: 'bundle', stockQuantity: 25),
        ],

        /// ── MediCare Pharmacy ──
        'shop_005': [
          ProductModel(productId: 'p027', shopId: 'shop_005', name: 'Napa Extra (10 tabs)', category: 'Pain Relief', price: 45, unit: 'strip', stockQuantity: 100),
          ProductModel(productId: 'p028', shopId: 'shop_005', name: 'Antacid Suspension (200ml)', category: 'Digestive', price: 120, unit: 'bottle', stockQuantity: 30),
          ProductModel(productId: 'p029', shopId: 'shop_005', name: 'Vitamin C (30 tabs)', category: 'Vitamins', price: 180, unit: 'bottle', stockQuantity: 25),
          ProductModel(productId: 'p030', shopId: 'shop_005', name: 'Band-Aid (10pc)', category: 'First Aid', price: 60, unit: 'box', stockQuantity: 40),
          ProductModel(productId: 'p031', shopId: 'shop_005', name: 'Hand Sanitizer (200ml)', category: 'Hygiene', price: 95, unit: 'bottle', stockQuantity: 35),
        ],

        /// ── Daily Needs Store (Grocery #2) ──
        'shop_007': [
          ProductModel(productId: 'p032', shopId: 'shop_007', name: 'Bread (Large)', category: 'Bakery', price: 70, unit: 'piece', stockQuantity: 15),
          ProductModel(productId: 'p033', shopId: 'shop_007', name: 'Butter (200g)', category: 'Dairy', price: 220, unit: 'pack', stockQuantity: 10),
          ProductModel(productId: 'p034', shopId: 'shop_007', name: 'Tea Bags (50pc)', category: 'Beverages', price: 250, unit: 'box', stockQuantity: 20),
          ProductModel(productId: 'p035', shopId: 'shop_007', name: 'Biscuits Assorted', category: 'Snacks', price: 85, discountPrice: 70, unit: 'pack', stockQuantity: 30),
        ],
      };

  /// Get products for a specific shop
  static List<ProductModel> getProductsForShop(String shopId) {
    return allProducts[shopId] ?? [];
  }

  /// Get unique product categories for a shop
  static List<String> getProductCategories(String shopId) {
    final products = getProductsForShop(shopId);
    final cats = products.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  /// Search shops by name
  static List<ShopModel> searchShops(String query) {
    final lower = query.toLowerCase();
    return allShops.where((s) =>
        s.shopName.toLowerCase().contains(lower) ||
        s.category.toLowerCase().contains(lower) ||
        s.description.toLowerCase().contains(lower)).toList();
  }
}
