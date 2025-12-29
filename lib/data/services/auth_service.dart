
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _auth = Supabase.instance.client.auth;

  /// Email sign-in
  static Future<AuthResponse> signInEmail(String email, String password) async {
    try {
      return await _auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  /// Email sign-up
  static Future<AuthResponse> signUpEmail(String email, String password) async {
    try {
      return await _auth.signUp(password: password, email: email);
    } catch (e) {
      throw Exception("Signup failed: $e");
    }
  }

  /// Google login (tokens provided externally)
  static Future<AuthResponse> signInWithGoogle({
    required String idToken,
    required String? accessToken,
  }) async {
    try {
      return await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      throw Exception("Google login failed: $e");
    }
  }

  /// Logout
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
