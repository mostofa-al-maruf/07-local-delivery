/// ============================================================
/// auth_service.dart — Firebase Phone Authentication Service
/// ============================================================
/// Handles the complete OTP login flow:
///   1. Send OTP to phone number via Firebase Auth
///   2. Verify the OTP code entered by the user
///   3. Check/create user document in Firestore
//
/// Data Flow:
///   LoginScreen → AuthService.sendOTP() → Firebase Auth → SMS to phone
///   OTPScreen   → AuthService.verifyOTP() → Firebase Auth → UserCredential
///   AuthService → Firestore /users/{uid} → check/create user document
/// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// ── Current Firebase User ─────────────────────
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// ── Store verification ID between send & verify steps ──
  String? _verificationId;
  int? _resendToken;

  /// ──────────────────────────────────────────────
  /// STEP 1: Send OTP to phone number
  /// ──────────────────────────────────────────────
  // Initiates phone number verification.
  // [phone] must be in format: +8801XXXXXXXXX
  // [onCodeSent] callback fires when SMS is dispatched
  // [onError] callback fires on failure
  // [onAutoVerify] fires if auto-retrieval succeeds (Android only)
  Future<void> sendOTP({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential)? onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),

        // Called when OTP is auto-retrieved on Android
        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerify?.call(credential);
        },

        // Called when verification fails
        verificationFailed: (FirebaseAuthException e) {
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'Invalid phone number format.';
              break;
            case 'too-many-requests':
              message = 'Too many attempts. Please try again later.';
              break;
            default:
              message = e.message ?? 'Verification failed.';
          }
          onError(message);
        },

        // Called when OTP is sent successfully
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },

        // Called when auto-retrieval times out
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },

        // Use resend token for subsequent attempts
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError('Failed to send OTP: ${e.toString()}');
    }
  }

  /// ──────────────────────────────────────────────
  /// STEP 2: Verify OTP code entered by user
  /// ──────────────────────────────────────────────
  // Verifies the 6-digit OTP code and signs in the user.
  // Returns the authenticated UserCredential on success.
  Future<UserCredential> verifyOTP(String otpCode) async {
    if (_verificationId == null) {
      throw Exception('Verification ID not found. Please resend OTP.');
    }

    // Create credential from verification ID + user-entered code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otpCode,
    );

    // Sign in with the credential
    return await _auth.signInWithCredential(credential);
  }

  /// ──────────────────────────────────────────────
  /// STEP 3: Check if user exists in Firestore
  /// ──────────────────────────────────────────────
  // After successful auth, check if user document exists.
  // Returns UserModel if found, null if new user.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null; // New user — needs profile setup
  }

  /// ──────────────────────────────────────────────
  /// STEP 4: Create user document for new users
  /// ──────────────────────────────────────────────
  // Creates a new user document in Firestore.
  // Called after profile setup screen.
  Future<void> createUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  /// ──────────────────────────────────────────────
  /// STEP 5: Update existing user profile
  /// ──────────────────────────────────────────────
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// ──────────────────────────────────────────────
  // Sign Out (clears both Firebase + Google sessions)
  /// ──────────────────────────────────────────────
  Future<void> signOut() async {
    // Clear Google session so account picker appears next time
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ══════════════════════════════════════════════
  //  GOOGLE SIGN-IN (Milestone 3 — Secondary Login)
  // ══════════════════════════════════════════════

  /// ──────────────────────────────────────────────
  // Sign in with Google Account
  /// ──────────────────────────────────────────────
  // Opens the Google account picker, gets credentials,
  // and signs into Firebase with those credentials.
  Future<UserCredential> signInWithGoogle() async {
    // 1. Trigger the Google Sign-In flow (account picker)
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled.');
    }

    // 2. Get auth details from the Google account
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 3. Create a Firebase credential from Google tokens
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase with the Google credential
    return await _auth.signInWithCredential(credential);
  }
}
