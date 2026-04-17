/// ============================================================
/// otp_screen.dart — OTP Verification Screen
/// ============================================================
/// Second step of OTP authentication:
///   1. Displays 6 OTP input boxes (using Pinput package)
///   2. User enters the code received via SMS
///   3. Verifies with Firebase Auth
///   4. Routes to Profile Setup (new) or Home (existing)
//
/// Data Flow:
///   User enters 6-digit OTP → "Verify" tap
///     → AuthProvider.verifyOTP(code)
///     → AuthService.verifyOTP() → Firebase Auth credential check
///     → AuthService.getUserProfile(uid) → Firestore /users/{uid}
///     → If doc exists → AuthProvider.isNewUser = false → Home
///     → If no doc    → AuthProvider.isNewUser = true → ProfileSetup
/// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_router.dart';
import '../../config/app_theme.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  // Countdown timer for OTP resend button
  void _startResendTimer() {
    _resendTimer = 60;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) _canResend = true;
      });
      return _resendTimer > 0;
    });
  }

  // Verify the entered OTP
  void _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.verifyOTP(code);

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.isNewUser) {
        // New user — needs to set up profile
        Navigator.pushNamedAndRemoveUntil(
            context, AppRouter.profileSetup, (route) => false);
      } else {
        // Existing user — route based on role
        if (authProvider.user?.role == 'rider') {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRouter.riderHome, (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRouter.home, (route) => false);
        }
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// ── Pinput theme for OTP boxes ──────────────
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  /// ── Header ──────────────────────
                  Text(
                    'Verify OTP',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                      children: [
                        const TextSpan(text: 'We sent a 6-digit code to '),
                        TextSpan(
                          text: auth.phoneNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  /// ── OTP Input (Pinput) ──────────
                  Center(
                    child: Pinput(
                      controller: _otpController,
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      onCompleted: (_) => _handleVerify(),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// ── Resend Timer ────────────────
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: () {
                              auth.sendOTP(auth.phoneNumber, null);
                              _startResendTimer();
                            },
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Text(
                            'Resend code in ${_resendTimer}s',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                  ),
                  const SizedBox(height: 16),

                  /// ── Error Message ───────────────
                  if (auth.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(
                                  color: AppTheme.errorRed, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  /// ── Verify Button ───────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Verify & Continue →'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
