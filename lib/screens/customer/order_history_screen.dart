/// ============================================================
/// order_history_screen.dart — Order History Screen
/// ============================================================
/// Displays all past and active orders for the logged-in customer.
/// Each order card shows: order ID, shop name, items count,
/// total amount, status badge, and placed time.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../config/app_router.dart';
import '../../config/app_theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().uid;
      context.read<OrderProvider>().loadOrderHistory(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, AppRouter.home, (route) => false),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProv, _) {
          if (orderProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProv.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No orders yet',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Your order history will appear here',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRouter.home, (route) => false),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderProv.orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orderProv.orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Order ID + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                _statusBadge(order.status),
              ],
            ),
            const SizedBox(height: 8),

            // Shop name and type
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(order.shopName,
                    style: const TextStyle(color: AppTheme.textMuted)),
                const Text(' · ', style: TextStyle(color: AppTheme.textMuted)),
                Text(order.orderType,
                    style: TextStyle(
                      color: AppTheme.categoryColors[order.orderType] ??
                          AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
            const SizedBox(height: 8),

            // Total and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '৳${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(order.placedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = AppTheme.warningAmber;
        label = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmed';
        break;
      case 'assigned':
        color = Colors.indigo;
        label = 'Rider Assigned';
        break;
      case 'picked_up':
        color = Colors.teal;
        label = 'Picked Up';
        break;
      case 'delivered':
        color = AppTheme.successGreen;
        label = 'Delivered';
        break;
      case 'cancelled':
        color = AppTheme.errorRed;
        label = 'Cancelled';
        break;
      default:
        color = AppTheme.textMuted;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
