/// ============================================================
/// product_card.dart — Product List Item Widget
/// ============================================================
/// Displays a product on the Shop Detail screen with:
///   - Product image placeholder
///   - Name, price, unit, discount badge
///   - Add to Cart / Quantity controls
//
/// Handles the "different shop" dialog when adding items
/// from a new shop while cart has items from another.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../config/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final String shopName;

  const ProductCard({
    super.key,
    required this.product,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final inCart = cartProvider.isInCart(product.productId);
    final quantity = cartProvider.getQuantity(product.productId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image placeholder
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, color: AppTheme.textMuted),
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined,
                    color: AppTheme.textMuted, size: 32),
          ),
          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Unit info
                Text(
                  'per ${product.unit}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),

                // Price row
                Row(
                  children: [
                    Text(
                      '৳${product.effectivePrice.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '৳${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Add / Quantity controls
          if (!inCart)
            // "Add" button
            SizedBox(
              width: 70,
              height: 36,
              child: ElevatedButton(
                onPressed: () => _handleAddToCart(context, cartProvider),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 13)),
              ),
            )
          else
            // Quantity controls (+/-)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qtyButton(Icons.remove, () {
                    cartProvider.decrementItem(product.productId);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$quantity',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  _qtyButton(Icons.add, () {
                    cartProvider.incrementItem(product.productId);
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Handle add-to-cart with different-shop check
  void _handleAddToCart(BuildContext context, CartProvider cart) {
    if (cart.isDifferentShop(product.shopId)) {
      // Show dialog: cart has items from another shop
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Switch Shop?'),
          content: Text(
            'Your cart has items from "${cart.currentShopName}". '
            'Adding this item will clear your current cart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cart.switchShopAndAdd(product, shopName);
                Navigator.pop(context);
              },
              child: const Text('Switch & Add',
                  style: TextStyle(color: AppTheme.accentOrange)),
            ),
          ],
        ),
      );
    } else {
      cart.addItem(product, shopName);
    }
  }

  // Small +/- button
  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppTheme.primaryColor),
      ),
    );
  }
}
