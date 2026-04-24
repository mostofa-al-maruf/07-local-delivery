/// ============================================================
/// order_tracking_screen.dart — Live Order Tracking (Milestone 3)
/// ============================================================
/// Shows real-time rider location on an OpenStreetMap.
/// Uses StreamBuilder to listen to:
///   1. Order status changes (from Firestore)
///   2. Rider's GPS coordinates (from Firestore)
/// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  // Default to Dhaka center
  LatLng _riderPosition = const LatLng(23.8103, 90.4125);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Track Order', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.cardWhite,
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _orderService.streamOrderById(widget.orderId),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = orderSnapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return Column(
            children: [
              // Map Section
              Expanded(
                flex: 3,
                child: _buildMap(order),
              ),

              // Order Status Section
              Expanded(
                flex: 2,
                child: _buildStatusPanel(order),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(OrderModel order) {
    // If rider is assigned, stream their location
    if (order.riderId != null && order.riderId!.isNotEmpty) {
      return StreamBuilder<GeoPoint?>(
        stream: _locationService.streamRiderLocation(order.riderId!),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.hasData && locationSnapshot.data != null) {
            final geo = locationSnapshot.data!;
            _riderPosition = LatLng(geo.latitude, geo.longitude);
          }

          return _buildMapWidget(order);
        },
      );
    }

    return _buildMapWidget(order);
  }

  Widget _buildMapWidget(OrderModel order) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _riderPosition,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.cse489.localdelivery07',
        ),
        MarkerLayer(
          markers: [
            // Rider Marker
            if (order.riderId != null)
              Marker(
                point: _riderPosition,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPanel(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${order.orderId.substring(0, 6)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              _buildStatusChip(order.status),
            ],
          ),
          const SizedBox(height: 16),

          // Status Timeline
          _buildTrackingTimeline(order.status),

          const SizedBox(height: 16),

          // Rider Info
          if (order.riderId != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .doc(order.orderId)
                        .snapshots(),
                    builder: (context, snap) {
                      final name = snap.data?.get('riderName') ?? 'Assigned';
                      final phone = snap.data?.get('riderPhone') ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Delivery Partner',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          Text(name.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (phone.toString().isNotEmpty)
                            Text(phone.toString(),
                                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
                        ],
                      );
                    },
                  ),
                ),
                // Call Rider Button
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .doc(order.orderId)
                      .snapshots(),
                  builder: (context, snap) {
                    final phone = snap.data?.get('riderPhone') ?? '';
                    if (phone.toString().isEmpty) return const SizedBox();
                    return GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: AppTheme.successGreen, size: 22),
                      ),
                    );
                  },
                ),
              ],
            ),
          ] else
            Center(
              child: Text(
                'Waiting for a rider to accept your order...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = switch (status) {
      'pending' => AppTheme.warningAmber,
      'accepted' => AppTheme.primaryColor,
      'picked_up' => AppTheme.accentOrange,
      'delivered' => AppTheme.successGreen,
      _ => AppTheme.textMuted,
    };
    final label = switch (status) {
      'pending' => 'Pending',
      'accepted' => 'Accepted',
      'picked_up' => 'On the Way',
      'delivered' => 'Delivered',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildTrackingTimeline(String currentStatus) {
    final steps = ['pending', 'accepted', 'picked_up', 'delivered'];
    final labels = ['Order Placed', 'Rider Accepted', 'Picked Up', 'Delivered'];
    final icons = [Icons.receipt_long, Icons.check_circle, Icons.local_shipping, Icons.home];
    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppTheme.successGreen : Colors.grey.shade200,
              ),
              child: Icon(
                icons[index],
                size: 16,
                color: isCompleted ? Colors.white : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? AppTheme.textDark : AppTheme.textMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}
