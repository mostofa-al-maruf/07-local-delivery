/// ============================================================
/// location_service.dart — GPS Location Service (Milestone 3)
/// ============================================================
/// Handles rider's real-time GPS tracking:
///   - Request location permissions
///   - Start/stop location updates
///   - Push lat/lng to Firestore every 10 seconds
///
/// Firestore path: /users/{riderId}/location
/// ============================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSub;
  Timer? _throttleTimer;
  Position? _lastPosition;

  /// ──────────────────────────────────────────────
  // Check & Request Location Permissions
  /// ──────────────────────────────────────────────
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// ──────────────────────────────────────────────
  // Start tracking rider's location
  /// ──────────────────────────────────────────────
  // Updates Firestore every ~10 seconds with the rider's lat/lng.
  Future<void> startTracking(String riderId) async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return;

    // Get initial position
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (_lastPosition != null) {
        await _updateFirestore(riderId, _lastPosition!);
      }
    } catch (e) {
      // Silently handle — will retry on stream
    }

    // Start continuous updates
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Only fire when moved 10+ meters
      ),
    ).listen((Position position) {
      _lastPosition = position;
    });

    // Throttle Firestore writes to every 10 seconds
    _throttleTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_lastPosition != null) {
        _updateFirestore(riderId, _lastPosition!);
      }
    });
  }

  /// ──────────────────────────────────────────────
  // Push location to Firestore
  /// ──────────────────────────────────────────────
  Future<void> _updateFirestore(String riderId, Position position) async {
    await _firestore.collection('users').doc(riderId).update({
      'liveLocation': GeoPoint(position.latitude, position.longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ──────────────────────────────────────────────
  // Stream rider's location from Firestore (for customer to watch)
  /// ──────────────────────────────────────────────
  Stream<GeoPoint?> streamRiderLocation(String riderId) {
    return _firestore
        .collection('users')
        .doc(riderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return data['liveLocation'] as GeoPoint?;
    });
  }

  /// ──────────────────────────────────────────────
  // Stop tracking
  /// ──────────────────────────────────────────────
  void stopTracking() {
    _positionSub?.cancel();
    _throttleTimer?.cancel();
    _positionSub = null;
    _throttleTimer = null;
  }
}
