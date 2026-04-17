/// ============================================================
/// cart_screen.dart — Shopping Cart Screen
/// ============================================================
/// Displays all items in the cart with:
///   - Item list with +/- quantity controls
///   - Price breakdown (subtotal, delivery fee, platform fee, total)
///   - "Proceed to Checkout" button
//
/// Data Flow:
///   CartProvider.itemsList → displayed in ListView
///   +/- buttons → CartProvider.incrementItem() / decrementItem()
///   Delete icon → CartProvider.removeItem()
///   "Checkout" tap → Navigate to CheckoutScreen
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_router.dart';
import '../../config/app_theme.dart';
import '../../widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart 🛒'),
        actions: [
          // Clear cart button
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClearCart(context, cart),
                child: const Text('Clear All',
                    style: TextStyle(color: AppTheme.errorRed)),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          /// ── Empty Cart State ──────────────────
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Add items from a shop to get started',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRouter.home, (route) => false),
                    child: const Text('Browse Shops'),
                  ),
                ],
              ),
            );
          }

          /// ── Cart with Items ───────────────────
          return Column(
            children: [
              // Shop name header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    const Icon(Icons.store,
                        size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      cart.currentShopName ?? 'Shop',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Item list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.itemsList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cart.itemsList[index];
                    return CartItemTile(item: item);
                  },
                ),
              ),

              /// ── Price Breakdown ─────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _priceRow('Subtotal', cart.subtotal),
                      const SizedBox(height: 6),
                      _priceRow('Delivery Fee', cart.deliveryFee),
                      const SizedBox(height: 6),
                      _priceRow('Platform Fee', cart.platformFee),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),
                      _priceRow('Total', cart.totalAmount, isTotal: true),
                      const SizedBox(height: 16),

                      // Checkout button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.checkout),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                          ),
                          child: Text(
                            'Proceed to Checkout · ৳${cart.totalAmount.toStringAsFixed(0)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Price row widget
  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? AppTheme.textDark : AppTheme.textMuted,
          ),
        ),
        Text(
          '৳${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  // Confirmation dialog before clearing cart
  void _confirmClearCart(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}
