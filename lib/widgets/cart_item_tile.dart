/// ============================================================
/// cart_item_tile.dart — Cart Item Row Widget
/// ============================================================
/// Displays a single cart item on the Cart screen with:
///   - Product image/icon
///   - Name, unit price × quantity = total
///   - Quantity +/- controls
///   - Delete button
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../config/app_theme.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Product image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(item.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppTheme.textMuted)),
                  )
                : const Icon(Icons.shopping_bag_outlined,
                    color: AppTheme.textMuted),
          ),
          const SizedBox(width: 12),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '৳${item.unitPrice.toStringAsFixed(0)} × ${item.quantity} = ৳${item.totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _qtyButton(Icons.remove, () {
                  cart.decrementItem(item.productId);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.quantity}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                _qtyButton(Icons.add, () {
                  cart.incrementItem(item.productId);
                }),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          IconButton(
            onPressed: () => cart.removeItem(item.productId),
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.errorRed, size: 22),
            tooltip: 'Remove item',
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppTheme.textDark),
      ),
    );
  }
}
