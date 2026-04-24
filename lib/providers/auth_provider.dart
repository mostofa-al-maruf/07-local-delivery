/// ============================================================
/// auth_provider.dart — Authentication State Management
/// ============================================================
/// Manages auth flow. In DEMO MODE, bypasses Firebase Auth
/// and uses mock user data from DemoData.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../config/demo_data.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  /// ── State Variables ───────────────────────────
  bool _isLoading = false;
  bool _isOTPSent = false;
  bool _isAuthenticated = false;
  bool _isNewUser = false;
  String _phoneNumber = '';
  String _selectedRole = 'customer'; // Added for role tracking
  // ignore: unused_field — used for state tracking and cleared on signOut
  String _verificationId = '';
  String? _errorMessage;
  UserModel? _user;

  /// ── Getters ───────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isOTPSent => _isOTPSent;
  bool get isAuthenticated => _isAuthenticated;
  bool get isNewUser => _isNewUser;
  String get phoneNumber => _phoneNumber;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  String get uid => DemoData.isDemoMode
      ? (DemoData.demoUser.uid)
      : (_authService.currentUser?.uid ?? '');

  /// ──────────────────────────────────────────────
  // Check auth state on app start
  /// ──────────────────────────────────────────────
  Future<void> checkAuthState() async {
    if (DemoData.isDemoMode) {
      // In demo mode, don't auto-login — go to login screen
      return;
    }
    if (_authService.isLoggedIn) {
      _isAuthenticated = true;
      _user = await _authService.getUserProfile(_authService.currentUser!.uid);
      _isNewUser = _user == null;
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  /// DEMO LOGIN — Instant login with mock data
  /// ──────────────────────────────────────────────
  void demoLogin() {
    _user = DemoData.demoUser;
    _phoneNumber = _user!.phone;
    _isAuthenticated = true;
    _isNewUser = false;
    _isOTPSent = false;
    notifyListeners();
  }

  Future<void> sendOTP(String phone, String? role, {VoidCallback? onSuccess, Function(String)? onError}) async {
    _isLoading = true;
    _errorMessage = null;
    _phoneNumber = phone;
    if (role != null) _selectedRole = role; // Store selected role
    notifyListeners();

    if (DemoData.isDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      _isOTPSent = true;
      _isLoading = false;
      notifyListeners();
      if (onSuccess != null) onSuccess();
      return;
    }

    await _authService.sendOTP(
      phone: phone,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        _isOTPSent = true;
        _isLoading = false;
        notifyListeners();
        if (onSuccess != null) onSuccess();
      },
      onError: (error) {
        _errorMessage = error;
        _isLoading = false;
        notifyListeners();
        if (onError != null) onError(error);
      },
      onAutoVerify: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _handlePostAuth();
        } catch (e) {
          _errorMessage = 'Auto-verification failed.';
          _isLoading = false;
          notifyListeners();
          if (onError != null) onError(_errorMessage!);
        }
      },
    );
  }

  /// ──────────────────────────────────────────────
  /// STEP 2: Verify OTP
  /// ──────────────────────────────────────────────
  Future<void> verifyOTP(String otpCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (DemoData.isDemoMode) {
      // In demo mode, accept any 6-digit code
      await Future.delayed(const Duration(milliseconds: 800));
      _user = DemoData.demoUser;
      _isAuthenticated = true;
      _isNewUser = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await _authService.verifyOTP(otpCode);
      await _handlePostAuth();
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.code == 'invalid-verification-code'
          ? 'Invalid OTP. Please try again.'
          : e.message ?? 'Verification failed.';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Verification failed. Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  // Post-auth: Check if user profile exists
  /// ──────────────────────────────────────────────
  Future<void> _handlePostAuth() async {
    final uid = _authService.currentUser!.uid;
    _user = await _authService.getUserProfile(uid);
    _isAuthenticated = true;
    _isNewUser = _user == null;

    // Existing user: use their saved role from Firestore (no role switching)
    // New user: _selectedRole will be used during profile creation

    _isLoading = false;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  // Create profile for new users
  /// ──────────────────────────────────────────────
  Future<void> createProfile({
    required String name,
    String address = '',
    String phone = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    // Use provided phone, or fall back to OTP phone number
    final userPhone = phone.isNotEmpty ? phone : _phoneNumber;

    if (DemoData.isDemoMode) {
      _user = UserModel(
        uid: 'demo_user_001',
        phone: userPhone,
        name: name,
        role: _selectedRole,
        address: address,
      );
      _isNewUser = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final newUser = UserModel(
      uid: _authService.currentUser!.uid,
      phone: userPhone,
      name: name,
      email: _authService.currentUser!.email ?? '',
      role: _selectedRole,
      address: address,
    );

    try {
      await _authService.createUserProfile(newUser);
      _user = newUser;
      _isNewUser = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to create profile: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  // Sign Out
  /// ──────────────────────────────────────────────
  Future<void> signOut() async {
    if (!DemoData.isDemoMode) {
      await _authService.signOut();
    }
    _isAuthenticated = false;
    _isOTPSent = false;
    _user = null;
    _phoneNumber = '';
    _verificationId = '';
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update the locally cached user model (after profile edit)
  void updateLocalUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  /// Cancel any stuck loading state
  void cancelLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════
  //  GOOGLE SIGN-IN (Milestone 3)
  // ══════════════════════════════════════════════

  /// ──────────────────────────────────────────────
  // Sign in with Google Account
  /// ──────────────────────────────────────────────
  Future<void> signInWithGoogle({String? role}) async {
    _isLoading = true;
    _errorMessage = null;
    if (role != null) _selectedRole = role;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      await _handlePostAuth();
    } catch (e) {
      final msg = e.toString();
      // User cancelled or pressed back — not an error, just reset
      if (msg.contains('cancelled') || msg.contains('canceled') || msg.contains('null')) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      _errorMessage = 'Google Sign-In failed: $msg';
      _isLoading = false;
      notifyListeners();
    }
  }
}
