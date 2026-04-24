/// ============================================================
/// rider_home_screen.dart — Rider Dashboard (Milestone 3)
/// ============================================================
/// Full rider workflow with real Firestore data:
///   1. Go Online → Listen for pending orders
///   2. New order alert → Accept/Decline
///   3. Active delivery → Picked Up → Delivered
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../config/app_theme.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riderInfo = context.watch<RiderProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.name.split(' ').first ?? 'Partner'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  riderInfo.isOnline ? 'Online • Ready for orders' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: riderInfo.isOnline
                        ? AppTheme.successGreen
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRouter.login, (route) => false);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Toggle Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMetricsRow(riderInfo),
                      const SizedBox(height: 24),
                      _buildOnlineToggle(riderInfo, user?.uid ?? ''),
                    ],
                  ),
                ),

                Expanded(
                  child: riderInfo.isOnline
                      ? (riderInfo.isOrderAccepted
                          ? _buildActiveDeliveryView(riderInfo)
                          : _buildSearchingRadar(riderInfo))
                      : _buildOfflineState(),
                ),
              ],
            ),

            // Incoming Request Modal Overlay
            if (riderInfo.hasIncomingRequest && !riderInfo.isOrderAccepted)
              _buildIncomingRequestModal(riderInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(RiderProvider riderInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard('Earnings', '৳${riderInfo.earningsToday.toStringAsFixed(0)}', Icons.account_balance_wallet, AppTheme.successGreen),
        _buildMetricCard('Deliveries', '${riderInfo.totalDeliveries}', Icons.local_shipping, AppTheme.primaryColor),
        _buildMetricCard('Rating', '${riderInfo.rating} ★', Icons.star, AppTheme.warningAmber),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 72) / 3,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle(RiderProvider riderInfo, String riderId) {
    return GestureDetector(
      onTap: () => riderInfo.toggleOnlineStatus(!riderInfo.isOnline, riderId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: riderInfo.isOnline
                ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                : [Colors.grey.shade300, Colors.grey.shade400],
          ),
          boxShadow: [
            if (riderInfo.isOnline)
              BoxShadow(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
              )
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                riderInfo.isOnline ? 'YOU ARE ONLINE' : 'GO ONLINE',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: riderInfo.isOnline ? MediaQuery.of(context).size.width - 100 : 8,
              top: 4,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  riderInfo.isOnline ? Icons.power_settings_new : Icons.chevron_right,
                  color: riderInfo.isOnline ? const Color(0xFF27AE60) : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bedtime_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'You are currently offline',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go online to start receiving delivery requests\nand earn money.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingRadar(RiderProvider riderInfo) {
    final pendingCount = riderInfo.pendingOrders.length;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.2), width: 2),
                ),
              ),
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3), width: 2),
                ),
              ),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.location_on, color: AppTheme.accentOrange, size: 32),
              ),
              // Radar Sweep
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _radarController.value * 2 * math.pi,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          center: FractionalOffset.center,
                          colors: [
                            AppTheme.accentOrange.withValues(alpha: 0.0),
                            AppTheme.accentOrange.withValues(alpha: 0.4),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            pendingCount > 0
                ? '$pendingCount order(s) available nearby!'
                : 'Searching for nearby orders...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: pendingCount > 0 ? AppTheme.successGreen : AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestModal(RiderProvider riderInfo) {
    final order = riderInfo.pendingOrders.first;
    final user = context.read<AuthProvider>().user;
    final timeAgo = DateTime.now().difference(order.placedAt).inMinutes;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: AppTheme.warningAmber, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'New Delivery Request!',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${timeAgo}m ago • Order #${order.orderId.substring(0, 6)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              _buildRequestDetailRow(Icons.store, 'Pick up', order.shopName),
              const SizedBox(height: 12),
              _buildRequestDetailRow(Icons.location_on, 'Drop off', order.deliveryAddress),
              const SizedBox(height: 12),
              _buildRequestDetailRow(Icons.payments, 'Earning', '৳${order.deliveryFee.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              _buildRequestDetailRow(Icons.shopping_bag, 'Total Bill', '৳${order.totalAmount.toStringAsFixed(0)}'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => riderInfo.skipOrder(order.orderId),
                      child: const Text('Decline', style: TextStyle(color: AppTheme.textDark)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: riderInfo.isLoading ? null : () {
                        riderInfo.acceptOrder(
                          orderId: order.orderId,
                          riderId: user!.uid,
                          riderName: user.name,
                          riderPhone: user.phone,
                        );
                      },
                      child: riderInfo.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  /// ════════════════════════════════════════════════
  ///  ACTIVE DELIVERY VIEW (Status Progression)
  /// ════════════════════════════════════════════════
  Widget _buildActiveDeliveryView(RiderProvider riderInfo) {
    final order = riderInfo.activeOrder!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Delivery',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Order Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.orderId.substring(0, 6)}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    _buildStatusBadge(order.status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildOrderInfoRow(Icons.store, 'Shop', order.shopName),
                const SizedBox(height: 10),
                _buildOrderInfoRow(Icons.person, 'Customer', order.customerName),
                const SizedBox(height: 10),
                _buildOrderInfoRow(Icons.phone, 'Phone', order.customerPhone),
                const SizedBox(height: 10),
                _buildOrderInfoRow(Icons.location_on, 'Address', order.deliveryAddress),
                const SizedBox(height: 10),
                _buildOrderInfoRow(Icons.payments, 'Collect (COD)', '৳${order.totalAmount.toStringAsFixed(0)}'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Status Timeline
          _buildStatusTimeline(order.status),

          const Spacer(),

          // Action Button
          if (riderInfo.nextStatusAction.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: order.status == 'picked_up'
                      ? AppTheme.successGreen
                      : AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: riderInfo.isLoading ? null : () async {
                  await riderInfo.progressOrderStatus();
                  if (riderInfo.activeOrder == null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Delivery completed! Great job!'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                },
                child: riderInfo.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(riderInfo.nextStatusAction, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status) {
      'accepted' => AppTheme.warningAmber,
      'picked_up' => AppTheme.primaryColor,
      'delivered' => AppTheme.successGreen,
      _ => AppTheme.textMuted,
    };
    final label = switch (status) {
      'accepted' => 'Accepted',
      'picked_up' => 'Picked Up',
      'delivered' => 'Delivered',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildOrderInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = ['accepted', 'picked_up', 'delivered'];
    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final label = switch (steps[index]) {
          'accepted' => 'Accepted',
          'picked_up' => 'Picked Up',
          'delivered' => 'Delivered',
          _ => steps[index],
        };

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? AppTheme.successGreen : Colors.grey.shade300,
                      border: isCurrent
                          ? Border.all(color: AppTheme.successGreen, width: 3)
                          : null,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? AppTheme.textDark : AppTheme.textMuted,
                  )),
                ],
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: index < currentIndex ? AppTheme.successGreen : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
