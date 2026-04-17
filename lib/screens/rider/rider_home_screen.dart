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
                      _buildOnlineToggle(riderInfo),
                    ],
                  ),
                ),

                Expanded(
                  child: riderInfo.isOnline
                      ? (riderInfo.isOrderAccepted
                          ? _buildActiveDeliveryView(riderInfo)
                          : _buildSearchingRadar())
                      : _buildOfflineState(),
                ),
              ],
            ),

            // Incoming Request Modal Overlay
            if (riderInfo.hasIncomingRequest) _buildIncomingRequestModal(riderInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(RiderProvider riderInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard('Earnings', '৳${riderInfo.earningsToday}', Icons.account_balance_wallet, AppTheme.successGreen),
        _buildMetricCard('Deliveries', '${riderInfo.totalDeliveries}', Icons.local_shipping, AppTheme.primaryColor),
        _buildMetricCard('Rating', '${riderInfo.rating} ★', Icons.star, AppTheme.warningAmber),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 72) / 3, // evenly spaced
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

  Widget _buildOnlineToggle(RiderProvider riderInfo) {
    return GestureDetector(
      onTap: () => riderInfo.toggleOnlineStatus(!riderInfo.isOnline),
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

  Widget _buildSearchingRadar() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.2), width: 2),
                ),
              ),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3), width: 2),
                ),
              ),
              Container(
                width: 80,
                height: 80,
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
                      width: 200,
                      height: 200,
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
            'Searching for nearby orders...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestModal(RiderProvider riderInfo) {
    return Container(
      color: Colors.black54, // Dim background
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: AppTheme.warningAmber, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'New Delivery Request!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildRequestDetailRow(Icons.store, 'Pick up', 'Haque Store (Grocery)'),
              const SizedBox(height: 12),
              _buildRequestDetailRow(Icons.location_on, 'Drop off', 'Block C, Road 2, Banani'),
              const SizedBox(height: 12),
              _buildRequestDetailRow(Icons.payments, 'Earning', '৳40.00'),
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
                      onPressed: () => riderInfo.rejectOrder(),
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
                      onPressed: () => riderInfo.acceptOrder(),
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveDeliveryView(RiderProvider riderInfo) {
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
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text('Map Integration Placeholder\n(Will be added in Milestone 3)', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => riderInfo.completeOrder(),
              child: const Text('Mark as Delivered'),
            ),
          ),
        ],
      ),
    );
  }
}
