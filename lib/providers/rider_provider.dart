import 'package:flutter/material.dart';

class RiderProvider extends ChangeNotifier {
  bool _isOnline = false;
  bool _hasIncomingRequest = false;
  bool _isOrderAccepted = false;

  // Mock Metrics
  final double earningsToday = 450.0;
  final int totalDeliveries = 14;
  final double rating = 4.8;

  bool get isOnline => _isOnline;
  bool get hasIncomingRequest => _hasIncomingRequest;
  bool get isOrderAccepted => _isOrderAccepted;

  void toggleOnlineStatus(bool value) async {
    _isOnline = value;
    notifyListeners();

    if (_isOnline) {
      // Simulate an incoming request after 3 seconds of going online
      await Future.delayed(const Duration(seconds: 3));
      if (_isOnline && !_isOrderAccepted) {
        _hasIncomingRequest = true;
        notifyListeners();
      }
    } else {
      _hasIncomingRequest = false;
      notifyListeners();
    }
  }

  void acceptOrder() {
    _hasIncomingRequest = false;
    _isOrderAccepted = true;
    notifyListeners();
  }

  void rejectOrder() {
    _hasIncomingRequest = false;
    notifyListeners();
    
    // Simulate another request later
    Future.delayed(const Duration(seconds: 5), () {
      if (_isOnline && !_isOrderAccepted) {
        _hasIncomingRequest = true;
        notifyListeners();
      }
    });
  }

  void completeOrder() {
    _isOrderAccepted = false;
    notifyListeners();
  }
}
