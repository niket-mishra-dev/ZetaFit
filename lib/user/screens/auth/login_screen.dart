import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitmor/admin/routes/admin_routes.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final SupabaseClient supabase = Supabase.instance.client;

  // 🔑 GOOGLE SIGN-IN (USER AUTH ONLY)
  Future<void> _login(BuildContext context) async {
    try {
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

      final account = await googleSignIn.authenticate();
      final auth = account.authentication;

      if (auth.idToken == null) {
        throw Exception('No Google ID token');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: auth.idToken!,
      );

      // 🔁 IMPORTANT: Re-trigger AppGuard
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/login_bg.jpg",
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, 0.28, 0.6, 1.0],
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.72),
                      Color.fromRGBO(0, 0, 0, 0.60),
                      Color.fromRGBO(0, 0, 0, 0.28),
                      Color.fromRGBO(0, 0, 0, 0.05),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // 🔐 SECRET ADMIN ENTRY
                  GestureDetector(
                    onLongPress: () {
                      Navigator.pushNamed(context, AdminRoutes.login);
                    },
                    child: Text(
                      "ZetaFit",
                      style: GoogleFonts.michroma(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Stronger. Every Day.",
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const Spacer(),

                  _authButton(
                    icon: FontAwesomeIcons.google,
                    label: "Continue with Google",
                    background: Colors.white,
                    textColor: Colors.black,
                    onTap: () => _login(context),
                  ),

                  const SizedBox(height: 18),

                  _authButton(
                    icon: FontAwesomeIcons.apple,
                    label: "Continue with Apple",
                    background: Colors.black,
                    textColor: Colors.white,
                    border: Border.all(color: Colors.white70),
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _authButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color textColor,
    Border? border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
