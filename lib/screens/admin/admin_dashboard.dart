/// ============================================================
/// admin_dashboard.dart — Admin Web Dashboard (Milestone 3)
/// ============================================================
/// A responsive admin panel with:
///   - Orders Panel (all active orders with real-time status)
///   - Shops Panel (manage shop listings)
///   - Analytics Panel (revenue, commission, charts)
/// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/app_theme.dart';
import '../../config/app_router.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final OrderService _orderService = OrderService();
  int _selectedTab = 0;

  final List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.receipt_long, 'Orders'),
    _NavItem(Icons.store, 'Shops'),
    _NavItem(Icons.delivery_dining, 'Riders'),
    _NavItem(Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: isWide ? 240 : 72,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                if (isWide)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text('Admin Panel',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                  ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),

                // Nav Items
                ...List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isSelected = _selectedTab == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 16 : 0, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.15) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, color: Colors.white, size: 22),
                          if (isWide) ...[
                            const SizedBox(width: 12),
                            Text(item.label,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        isSelected ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Logout
                InkWell(
                  onTap: () {
                    context.read<AuthProvider>().signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRouter.login, (route) => false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment:
                          isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: Colors.white70, size: 20),
                        if (isWide) ...[
                          const SizedBox(width: 12),
                          const Text('Logout', style: TextStyle(color: Colors.white70)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildAnalyticsPanel();
      case 1:
        return _buildOrdersPanel();
      case 2:
        return _buildShopsPanel();
      case 3:
        return _buildRidersPanel();
      case 4:
        return _buildSettingsPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  // ════════════════════════════════════════════════
  //  ANALYTICS PANEL
  // ════════════════════════════════════════════════
  Widget _buildAnalyticsPanel() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.streamAllOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final totalSales = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
        final commission = orders.fold<double>(0, (sum, o) => sum + o.platformFee);
        final deliveredCount = orders.where((o) => o.status == 'delivered').length;
        final pendingCount = orders.where((o) => o.status == 'pending').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Platform Overview', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              const SizedBox(height: 32),

              // Stat Cards
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildStatCard('Total Sales', '৳${totalSales.toStringAsFixed(0)}',
                      Icons.trending_up, AppTheme.successGreen),
                  _buildStatCard('Commission', '৳${commission.toStringAsFixed(0)}',
                      Icons.account_balance, AppTheme.primaryColor),
                  _buildStatCard('Delivered', '$deliveredCount',
                      Icons.check_circle, AppTheme.secondaryColor),
                  _buildStatCard('Pending', '$pendingCount',
                      Icons.pending_actions, AppTheme.warningAmber),
                ],
              ),

              const SizedBox(height: 40),

              // Revenue Chart
              Text('Revenue Breakdown',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: _buildRevenueChart(orders),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<OrderModel> orders) {
    final delivered = orders.where((o) => o.status == 'delivered').length.toDouble();
    final accepted = orders.where((o) => o.status == 'accepted').length.toDouble();
    final pending = orders.where((o) => o.status == 'pending').length.toDouble();
    final pickedUp = orders.where((o) => o.status == 'picked_up').length.toDouble();

    if (delivered + accepted + pending + pickedUp == 0) {
      return const Center(child: Text('No orders yet'));
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                if (delivered > 0) PieChartSectionData(value: delivered, color: AppTheme.successGreen, showTitle: false),
                if (accepted > 0) PieChartSectionData(value: accepted, color: AppTheme.primaryColor, showTitle: false),
                if (pending > 0) PieChartSectionData(value: pending, color: AppTheme.warningAmber, showTitle: false),
                if (pickedUp > 0) PieChartSectionData(value: pickedUp, color: AppTheme.accentOrange, showTitle: false),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('Done', AppTheme.successGreen),
            _buildLegendItem('Active', AppTheme.primaryColor),
            _buildLegendItem('Pending', AppTheme.warningAmber),
            _buildLegendItem('Pickup', AppTheme.accentOrange),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ════════════════════════════════════════════════
  //  ORDERS PANEL
  // ════════════════════════════════════════════════
  Widget _buildOrdersPanel() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.streamAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All Orders', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${orders.length} total orders', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderRow(order);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderRow(OrderModel order) {
    final statusColor = switch (order.status) {
      'pending' => AppTheme.warningAmber,
      'accepted' => AppTheme.primaryColor,
      'picked_up' => AppTheme.accentOrange,
      'delivered' => AppTheme.successGreen,
      _ => AppTheme.textMuted,
    };

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: isWide 
      ? Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt, color: statusColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.orderId.substring(0, 6)} • ${order.shopName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${order.customerName} • ${DateFormat('MMM dd, hh:mm a').format(order.placedAt)}',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text('৳${order.totalAmount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(order.status.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      )
      : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order.orderId.substring(0, 6)} • ${order.shopName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('৳${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${order.customerName} • ${DateFormat('MMM dd').format(order.placedAt)}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(order.status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  SHOPS PANEL
  // ════════════════════════════════════════════════
  Widget _buildShopsPanel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final shops = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shop Listings', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${shops.length} registered shops', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final data = shops[index].data() as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.store, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['shopName'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(data['category'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('★ ${(data['rating'] ?? 0).toStringAsFixed(1)}',
                              style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Switch(
                            value: isActive,
                            activeColor: AppTheme.successGreen,
                            onChanged: (val) {
                              FirebaseFirestore.instance
                                  .collection('shops')
                                  .doc(shops[index].id)
                                  .update({'isActive': val});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // ════════════════════════════════════════════════
  //  RIDERS PANEL
  // ════════════════════════════════════════════════
  Widget _buildRidersPanel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'rider').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final riders = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Partners', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${riders.length} registered riders', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: riders.length,
                  itemBuilder: (context, index) {
                    final data = riders[index].data() as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? true;
                    final deliveries = data['totalDeliveries'] ?? 0;
                    final earnings = data['totalEarnings'] ?? 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.pedal_bike, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'Unknown Rider',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(data['phone'] ?? 'No phone', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$deliveries Deliveries', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('৳$earnings Earned', style: const TextStyle(color: AppTheme.successGreen, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Switch(
                            value: isActive,
                            activeColor: AppTheme.successGreen,
                            onChanged: (val) {
                              FirebaseFirestore.instance.collection('users').doc(riders[index].id).update({'isActive': val});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════
  //  SETTINGS PANEL (COMMISSION)
  // ════════════════════════════════════════════════
  Widget _buildSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Global Settings', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Manage app-wide configurations', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text('Platform Commission Fee', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('This flat fee is added to every order as the platform\'s revenue. Currently hardcoded to ৳5 in checkout. Future update will sync this to Firestore.', 
                     style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: TextEditingController(text: '5.0'),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: '৳ ',
                          labelText: 'Fee Amount',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved. (Firestore sync planned for Phase 2)'))
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                      child: const Text('Update Fee', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
