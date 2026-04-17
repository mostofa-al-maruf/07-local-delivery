/// ============================================================
/// checkout_screen.dart — Order Checkout Screen
/// ============================================================
/// Final step before placing an order:
///   - Confirm/edit delivery address
///   - View order summary
///   - Select payment method (COD only in Phase 1)
///   - Place order → saves to Firestore with 'pending' status
//
/// Data Flow:
///   "Place Order" tap
///     → OrderProvider.placeOrder(cartItems, address, etc.)
///     → OrderService.submitOrder() → Firestore batch write
///       → /orders/{orderId} (main document)
///       → /orders/{orderId}/items/{itemId} (each line item)
///     → CartProvider.clearCart()
///     → Navigate to OrderConfirmationScreen
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../config/app_router.dart';
import '../../config/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with user's saved address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null && user.address.isNotEmpty) {
        _addressController.text = user.address;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Place the order
  void _handlePlaceOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orderProv = context.read<OrderProvider>();

    // Build order from cart state + user info
    final orderId = await orderProv.placeOrder(
      customerId: auth.uid,
      customerName: auth.user?.name ?? '',
      customerPhone: auth.user?.phone ?? '',
      shopId: cart.currentShopId!,
      shopName: cart.currentShopName!,
      orderType: 'grocery', // Determined by shop category
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      platformFee: cart.platformFee,
      deliveryAddress: _addressController.text.trim(),
      items: cart.itemsList,
      customerNote: _noteController.text.trim(),
    );

    if (orderId != null && mounted) {
      // Clear the cart after successful order
      cart.clearCart();

      // Navigate to confirmation screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.orderConfirmation,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProv = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── Delivery Address ──────────────────
            Text('Delivery Address',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'House #, Road, Area, City',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),

            /// ── Payment Method ───────────────────
            Text('Payment Method',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.successGreen, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.successGreen.withValues(alpha: 0.05),
              ),
              child: const Row(
                children: [
                  Icon(Icons.money, color: AppTheme.successGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash on Delivery',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Pay when you receive your order',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppTheme.successGreen),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// ── Special Instructions ─────────────
            Text('Special Instructions (Optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'E.g., Ring the bell, leave at door...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 24),

            /// ── Order Summary ────────────────────
            Text('Order Summary',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(cart.currentShopName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // List each item
                  ...cart.itemsList.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('${item.quantity}x ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Expanded(child: Text(item.productName)),
                            Text('৳${item.totalPrice.toStringAsFixed(0)}'),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  _summaryRow('Subtotal', cart.subtotal),
                  _summaryRow('Delivery Fee', cart.deliveryFee),
                  _summaryRow('Platform Fee', cart.platformFee),
                  const Divider(height: 20),
                  _summaryRow('Total', cart.totalAmount, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// ── Error Message ────────────────────
            if (orderProv.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(orderProv.errorMessage!,
                    style: const TextStyle(color: AppTheme.errorRed)),
              ),
            const SizedBox(height: 16),

            /// ── Place Order Button ───────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: orderProv.isLoading ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                ),
                child: orderProv.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Place Order · ৳${cart.totalAmount.toStringAsFixed(0)} →'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                fontSize: isTotal ? 16 : 14,
              )),
          Text(
            '৳${value.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
