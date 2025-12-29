import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final supabase = Supabase.instance.client;

  // ⭐ DO NOT CHANGE (Your original code remains exactly the same)
  Future<AuthResponse> _googleSignIn() async {
    const webClientId =
        '1005963315728-5caokqh8fqoo6o8f9or0m8esrmkevkmp.apps.googleusercontent.com';

    const iosClientId =
        '1005963315728-j9525d8vfph6evlc7e3mso8o03plg3or.apps.googleusercontent.com';

    final GoogleSignIn signIn = GoogleSignIn.instance;

    unawaited(
      signIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      ),
    );

    final googleAccount = await signIn.authenticate();
    final googleAuthorization = await googleAccount.authorizationClient
        .authorizationForScopes(['email', 'profile']);

    final googleAuthentication = googleAccount.authentication;
    final idToken = googleAuthentication.idToken;
    final accessToken = googleAuthorization?.accessToken;

    if (idToken == null) throw 'No ID Token found.';

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // BACKGROUND
            Positioned.fill(
              child: Image.asset(
                "assets/images/login_bg.jpg",
                fit: BoxFit.cover,
              ),
            ),

            // GRADIENT OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.28, 0.6, 1.0],
                    colors: [
                      const Color.fromRGBO(0, 0, 0, 0.72),
                      const Color.fromRGBO(0, 0, 0, 0.60),
                      const Color.fromRGBO(0, 0, 0, 0.28),
                      const Color.fromRGBO(0, 0, 0, 0.05),
                    ],
                  ),
                ),
              ),
            ),

            // TOP GRADIENT
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      const Color.fromRGBO(0, 0, 0, 0.35),
                      const Color.fromRGBO(0, 0, 0, 0.03),
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

                  // TITLE
                  Center(
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
                      color: const Color.fromRGBO(255, 255, 255, 0.85),
                      fontSize: 14,
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      "Continue with",
                      style: GoogleFonts.montserrat(
                        color: const Color.fromRGBO(255, 255, 255, 0.70),
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // GOOGLE BUTTON
                  _authButton(
                    icon: FontAwesomeIcons.google,
                    label: "Continue with Google",
                    background: Colors.white,
                    textColor: Colors.black87,
                    onTap: () async {
                      try {
                        final response = await _googleSignIn();
                        if (response.user != null && kDebugMode) {
                          if (kDebugMode) {
                            print('User ID: ${response.user!.id}');
                          }
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error during Google Sign-In: $e');
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  // APPLE BUTTON
                  _authButton(
                    icon: FontAwesomeIcons.apple,
                    label: "Continue with Apple",
                    background: Colors.black,
                    textColor: Colors.white,
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.70),
                      width: 1.2,
                    ),
                    onTap: () {},
                  ),

                  const SizedBox(height: 18),

                  Text(
                    "I accept the Terms & Privacy Policy",
                    style: GoogleFonts.montserrat(
                      color: const Color.fromRGBO(255, 255, 255, 0.70),
                      fontSize: 10,
                    ),
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

  // --------------------------
  // BUTTON WIDGET
  // --------------------------
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
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: textColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
