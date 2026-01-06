import 'dart:async';

import 'package:fitmor/admin/shell/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/state/app_state.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = false;

  // ===========================================================
  // 🔑 GOOGLE SIGN-IN (SINGLE SOURCE OF TRUTH)
  // ===========================================================

  Future<AuthResponse> _signInWithGoogle() async {
    const webClientId =
        '1005963315728-5caokqh8fqoo6o8f9or0m8esrmkevkmp.apps.googleusercontent.com';
    const iosClientId =
        '1005963315728-j9525d8vfph6evlc7e3mso8o03plg3or.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    unawaited(
      googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      ),
    );

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google ID token not found');
    }

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  // ===========================================================
  // 🚀 LOGIN FLOW
  // ===========================================================

  Future<void> _handleLogin() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final authResponse = await _signInWithGoogle();
      final user = authResponse.user;

      if (user == null) {
        throw Exception('Authentication failed');
      }

      await _verifyAdmin(user.id);
    } catch (e) {
      await _supabase.auth.signOut();
      _showError('🚫 You are not authorized as admin');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===========================================================
  // 🛡 ADMIN VERIFICATION (DB LEVEL)
  // ===========================================================

  Future<void> _verifyAdmin(String userId) async {
    final admin = await _supabase
        .from('admin_users')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (admin == null) {
      throw Exception('User is not an admin');
    }

    if (!mounted) return;

    // 🔐 Update global app state
    context.read<AppState>().markAdmin();

    // 🚀 Hard redirect into Admin shell
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminShell()),
      (_) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Admin access granted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===========================================================
  // 🎨 UI
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    Color(0xFF12121A),
                    Color(0xFF0B0B0E),
                    Color(0xFF070709),
                  ],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ZETAFIT',
                          style: GoogleFonts.michroma(
                            fontSize: 36,
                            letterSpacing: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Admin Control Panel',
                          style: GoogleFonts.montserrat(color: Colors.white70),
                        ),
                        const SizedBox(height: 36),
            
                        _authButton(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Continue with Google',
                          onTap: _loading ? null : _handleLogin,
                        ),
            
                        if (_loading) ...[
                          const SizedBox(height: 24),
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        ],
            
                        const SizedBox(height: 24),
                        Text(
                          'Restricted access • Admins only',
                          style: GoogleFonts.montserrat(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        
            _backButton(context), 
            ],
        ),
      ),
    );
  }

  // ===========================================================
  // 🔘 BUTTON
  // ===========================================================

  Widget _authButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // ❌ ERROR HANDLER
  // ===========================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _backButton(BuildContext context) {
  return Positioned(
    top: 16,
    left: 16,
    child: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: Colors.white70,
      onPressed: () {
        Navigator.of(context).maybePop();
      },
    ),
  );
}
  
}
