/// ============================================================
/// shop_detail_screen.dart — Shop Products Listing
/// ============================================================
/// Shows products of a selected shop with:
///   - Shop banner & info
///   - Sub-category tabs (All, Fruits, Dairy, etc.)
///   - Product cards with Add to Cart functionality
///   - Cart summary bar at bottom
//
/// Data Flow:
///   Screen opens with ShopModel via route arguments
///     → ProductProvider.loadProducts(shopId)
///     → Firestore /shops/{shopId}/products/
///     → Products displayed in list
///   "Add" tap → CartProvider.addItem(product, shopName)
///     → Cart badge and summary bar update reactively
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/shop_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_router.dart';
import '../../config/app_theme.dart';
import '../../widgets/product_card.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  ShopModel? _shop;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    /// Get shop from route arguments (passed from HomeScreen)
    final shop = ModalRoute.of(context)?.settings.arguments as ShopModel?;
    if (shop != null && _shop == null) {
      _shop = shop;
      /// Load products for this shop
      context.read<ProductProvider>().loadProducts(shop.shopId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shop == null) {
      return const Scaffold(body: Center(child: Text('Shop not found')));
    }

    final shop = _shop!;
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          /// ── Shop Banner (Sliver App Bar) ──────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.categoryColors[shop.category] ??
                          AppTheme.primaryColor,
                      AppTheme.primaryColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(shop.categoryIcon,
                          style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        shop.shopName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${shop.rating.toStringAsFixed(1)} · ${shop.addressText}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          /// ── Category Tabs ─────────────────────
          SliverToBoxAdapter(
            child: Consumer<ProductProvider>(
              builder: (context, prodProv, _) {
                if (prodProv.categories.length <= 1) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: prodProv.categories.length,
                    itemBuilder: (context, index) {
                      final cat = prodProv.categories[index];
                      final isSelected = prodProv.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => prodProv.selectCategory(cat),
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          /// ── Product List ──────────────────────
          Consumer<ProductProvider>(
            builder: (context, prodProv, _) {
              if (prodProv.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (prodProv.products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📦', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No products available',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = prodProv.products[index];
                      return ProductCard(
                        product: product,
                        shopName: shop.shopName,
                      );
                    },
                    childCount: prodProv.products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      /// ── Cart Summary Bar (Bottom) ─────────────
      bottomSheet: cartProvider.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRouter.cart),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cartProvider.totalQuantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${cartProvider.itemCount} items · ৳${cartProvider.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const Text(
                        'View Cart →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
