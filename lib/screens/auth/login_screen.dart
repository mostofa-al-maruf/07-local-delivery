/// ============================================================
/// login_screen.dart — Phone Number Entry Screen
/// ============================================================
/// First step of OTP authentication:
///   1. User enters their phone number (+880 prefix)
///   2. Taps "Send OTP" → triggers Firebase Phone Auth
///   3. On success → navigates to OTP verification screen
//
/// Data Flow:
///   User types phone → "Send OTP" tap
///     → AuthProvider.sendOTP(phone)
///     → AuthService.sendOTP() → Firebase Auth
///     → SMS dispatched → AuthProvider.isOTPSent = true
///     → Navigator.push(OTPScreen)
/// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_router.dart';
import '../../config/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'customer'; // Toggle between customer and rider
  bool _useEmailLogin = false; // Toggle between phone and email
  bool _isRegisterMode = false; // Toggle between login and register

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validates phone and triggers OTP send
  void _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+880${_phoneController.text.trim()}';

    final authProvider = context.read<AuthProvider>();
    await authProvider.sendOTP(
      phone, 
      _selectedRole,
      onSuccess: () {
        if (mounted) {
          Navigator.pushNamed(context, AppRouter.otp);
        }
      },
      onError: (String error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  // Handles email login/register
  void _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isRegisterMode) {
      await authProvider.registerWithEmail(
        email: email,
        password: password,
        role: _selectedRole,
      );
    } else {
      await authProvider.signInWithEmail(
        email: email,
        password: password,
        role: _selectedRole,
      );
    }

    if (!mounted) return;
    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (authProvider.isAuthenticated) {
      if (authProvider.isNewUser) {
        Navigator.pushReplacementNamed(context, AppRouter.profileSetup);
      } else {
        final role = authProvider.user?.role ?? 'customer';
        if (role == 'rider') {
          Navigator.pushReplacementNamed(context, AppRouter.riderHome);
        } else if (role == 'admin') {
          Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.home);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    /// ── Logo & Welcome ──────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '07',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Welcome to\n07 Local Delivery',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _useEmailLogin
                          ? 'Sign in with your email address'
                          : 'Enter your mobile number to continue',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                    const SizedBox(height: 40),

                    /// ── Role Selector ────────────────
                    Text(
                      'Login as',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildRoleChip('Customer', 'customer', Icons.person),
                        const SizedBox(width: 12),
                        _buildRoleChip(
                            'Delivery Partner', 'rider', Icons.delivery_dining),
                      ],
                    ),
                    const SizedBox(height: 32),

                    /// ── Login Method Toggle ─────────
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMethodTab('Phone', Icons.phone, !_useEmailLogin, () {
                              setState(() => _useEmailLogin = false);
                            }),
                            _buildMethodTab('Email', Icons.email, _useEmailLogin, () {
                              setState(() => _useEmailLogin = true);
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// ── Conditional Input Fields ─────
                    if (!_useEmailLogin) ...[
                      /// ── Phone Number Input ───────────
                      Text(
                        'Mobile Number',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Text(
                              '+880',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          hintText: '1XXXXXXXXX',
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.trim().length != 10) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      /// ── Email Input ───────────────────
                      Text(
                        'Email Address',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'your@email.com',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// ── Password Input ────────────────
                      Text(
                        'Password',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          hintText: '••••••',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.trim().length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    /// ── Error Message ────────────────
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
                    const SizedBox(height: 24),

                    /// ── Action Button ──────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : (_useEmailLogin ? _handleEmailAuth : _handleSendOTP),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(_useEmailLogin
                                ? (_isRegisterMode ? 'Create Account →' : 'Sign In →')
                                : 'Send OTP →'),
                      ),
                    ),

                    /// ── Toggle Register/Login for Email ──
                    if (_useEmailLogin) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() => _isRegisterMode = !_isRegisterMode);
                          },
                          child: Text(
                            _isRegisterMode
                                ? 'Already have an account? Sign In'
                                : "Don't have an account? Register",
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    /// ── Terms ────────────────────────
                    Center(
                      child: Text(
                        'By continuing, you agree to our\nTerms of Service & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Builds a login method tab (Phone / Email)
  Widget _buildMethodTab(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  // Builds a selectable role chip (Customer / Delivery Partner)
  Widget _buildRoleChip(String label, String value, IconData icon) {
    final isSelected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
