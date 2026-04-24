/// ============================================================
/// home_screen.dart — Customer Home Screen
/// ============================================================
/// The main landing page after login showing:
///   - Location bar at top
///   - Search bar
///   - Category tabs (Grocery, Fish, Meat, etc.)
///   - Grid/list of nearby shops filtered by category
//
/// Data Flow:
///   Screen loads → ShopProvider.loadShops()
///     → Fetches all verified shops from Firestore
///   Category tab tap → ShopProvider.selectCategory('fish')
///     → Re-fetches shops filtered by category
///   Shop card tap → Navigate to ShopDetailScreen with shopId
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_router.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/shop_card.dart';
import '../../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all shops when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// ── Top Bar (Location + Profile) ────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppTheme.accentOrange, size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivering to',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          authProvider.user?.address.isNotEmpty == true
                              ? authProvider.user!.address
                              : 'Set your address',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                  // Profile avatar
                  GestureDetector(
                    onTap: () => _showProfileMenu(context),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      backgroundImage: AuthService().currentUser?.photoURL != null
                          ? NetworkImage(AuthService().currentUser!.photoURL!)
                          : null,
                      child: AuthService().currentUser?.photoURL == null
                          ? Text(
                              (authProvider.user?.name ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// ── Search Bar ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (query) {
                  context.read<ShopProvider>().searchShops(query);
                },
                decoration: InputDecoration(
                  hintText: 'Search shops or products...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// ── Category Tabs (Horizontal Scroll) ──
            SizedBox(
              height: 100,
              child: Consumer<ShopProvider>(
                builder: (context, shopProv, _) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: ShopProvider.categories.length,
                    itemBuilder: (context, index) {
                      final cat = ShopProvider.categories[index];
                      final isSelected =
                          shopProv.selectedCategory == cat['key'];
                      return CategoryCard(
                        label: cat['label']!,
                        icon: cat['icon']!,
                        isSelected: isSelected,
                        onTap: () => shopProv.selectCategory(cat['key']!),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            /// ── Section Header ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<ShopProvider>(
                    builder: (context, shopProv, _) {
                      final label = shopProv.selectedCategory == 'all'
                          ? 'Nearby Shops'
                          : '${shopProv.selectedCategory[0].toUpperCase()}${shopProv.selectedCategory.substring(1)} Shops';
                      return Text(label,
                          style: Theme.of(context).textTheme.titleLarge);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            /// ── Shop Listing ────────────────────
            Expanded(
              child: Consumer<ShopProvider>(
                builder: (context, shopProv, _) {
                  if (shopProv.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (shopProv.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(shopProv.errorMessage!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => shopProv.loadShops(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (shopProv.shops.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏪', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'No shops found in this category',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: shopProv.shops.length,
                    itemBuilder: (context, index) {
                      final shop = shopProv.shops[index];
                      return ShopCard(
                        shop: shop,
                        onTap: () {
                          // Navigate to shop detail, passing the shop data
                          Navigator.pushNamed(
                            context,
                            AppRouter.shopDetail,
                            arguments: shop,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      /// ── Floating Cart Badge ─────────────────
      floatingActionButton: cartProvider.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '${cartProvider.totalQuantity} items · ৳${cartProvider.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white),
              ),
            ),

      /// ── Bottom Navigation Bar ─────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break; // Already on Home
            case 1:
              break; // Search (same screen)
            case 2:
              Navigator.pushNamed(context, AppRouter.orderHistory);
              break;
            case 3:
              _showProfileMenu(context);
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Shows a bottom sheet with profile options
  void _showProfileMenu(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: AuthService().currentUser?.photoURL != null
                  ? NetworkImage(AuthService().currentUser!.photoURL!)
                  : null,
              child: AuthService().currentUser?.photoURL == null
                  ? Text(
                      (auth.user?.name ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 28, color: AppTheme.primaryColor),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(auth.user?.name ?? 'User',
                style: Theme.of(context).textTheme.titleLarge),
            Text(auth.user?.phone ?? '',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.orderHistory);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: const Text('Logout',
                  style: TextStyle(color: AppTheme.errorRed)),
              onTap: () async {
                Navigator.pop(context);
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRouter.login, (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
