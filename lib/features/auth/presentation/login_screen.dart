import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../../../core/theme/glassmorphic_theme_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm(AuthProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    bool success;
    if (_isRegistering) {
      success = await provider.register(_emailController.text.trim(), _passwordController.text.trim());
    } else {
      success = await provider.signIn(_emailController.text.trim(), _passwordController.text.trim());
    }

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  void _submitGuest(AuthProvider provider) async {
    final ok = await provider.signInGuest();
    if (ok && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final glassTheme = Theme.of(context).extension<GlassmorphicThemeExtension>()!;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -200,
            left: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x226366F1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1F14B8A6),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: glassTheme.midnightBg,
                  borderRadius: BorderRadius.circular(20),
                  border: glassTheme.borderSubtle,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x1A6366F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.rocket_launch, color: Color(0xFF6366F1), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ResuMatch AI',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isRegistering ? 'Create your platform account' : 'Sign in to start career preparation',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Error message alert
                      if (authProvider.errorMessage.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x1AEF4444),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x40EF4444)),
                          ),
                          child: Text(
                            authProvider.errorMessage,
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email input
                      const Text(
                        'EMAIL ADDRESS',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'name@company.com',
                          hintStyle: const TextStyle(color: Color(0xFF475569)),
                          filled: true,
                          fillColor: const Color(0xFF0F131C),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF222B3E)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF6366F1)),
                          ),
                          errorStyle: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      const Text(
                        'PASSWORD',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: Color(0xFF475569)),
                          filled: true,
                          fillColor: const Color(0xFF0F131C),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF475569), size: 18),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF222B3E)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF6366F1)),
                          ),
                          errorStyle: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: authProvider.isLoading ? null : () => _submitForm(authProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          disabledBackgroundColor: const Color(0xFF1E293B),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : Text(
                                _isRegistering ? 'Register Account' : 'Sign In',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Guest bypass button
                      OutlinedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _submitGuest(authProvider),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF222B3E)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Continue as Guest', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      ),
                      const SizedBox(height: 20),

                      // Switch mode option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                            authProvider.signInGuest(); // clear errors
                          });
                        },
                        child: Text(
                          _isRegistering ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
