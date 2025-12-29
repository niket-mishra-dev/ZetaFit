// lib/core/providers/auth_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? user;
  Session? session;
  Map<String, dynamic>? profile;

  bool isLoading = false;
  String? errorMessage;

  StreamSubscription<AuthState>? _authSub;

  AuthProvider() {
    _initialize();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================
  void _initialize() {
    session = _supabase.auth.currentSession;
    user = _supabase.auth.currentUser;

    if (user != null) {
      fetchProfile();
    }

    _authSub = _supabase.auth.onAuthStateChange.listen((event) {
      session = event.session;
      user = event.session?.user ?? _supabase.auth.currentUser;

      if (kDebugMode) {
        print("[AuthProvider] Auth event: ${event.event}, user: ${user?.id}");
      }

      if (user != null) {
        fetchProfile();
      } else {
        profile = null;
      }

      notifyListeners();
    });
  }

  bool get isSignedIn => user != null;

  // ============================================================
  // SIGN-IN (Email)
  // ============================================================
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      user = response.user;
      session = response.session;
      errorMessage = null;

      if (user != null) {
        await fetchProfile();
      }
    } catch (e) {
      errorMessage = _error(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN-UP (Email)
  // ============================================================
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? extraProfileData,
  }) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      user = response.user;
      session = _supabase.auth.currentSession;
      errorMessage = null;

      // Optional: auto-create profile row
      if (user != null && extraProfileData != null) {
        await _supabase.from("profiles").upsert({
          "id": user!.id,
          ...extraProfileData,
        });
        await fetchProfile();
      }
    } catch (e) {
      errorMessage = _error(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN-IN WITH GOOGLE TOKEN
  // ============================================================
  Future<void> signInWithGoogleTokens({
    required String idToken,
    String? accessToken,
  }) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      user = response.user;
      session = response.session;
      errorMessage = null;

      if (user != null) {
        await fetchProfile();
      }
    } catch (e) {
      errorMessage = _error(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN-OUT
  // ============================================================
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabase.auth.signOut();
      user = null;
      session = null;
      profile = null;
      errorMessage = null;
    } catch (e) {
      errorMessage = _error(e);
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================
  Future<void> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      errorMessage = null;
    } catch (e) {
      errorMessage = _error(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REFRESH SESSION
  // ============================================================
  Future<void> refreshSession() async {
    _setLoading(true);
    try {
      final newSession = await _supabase.auth.refreshSession();
      session = newSession.session;
      user = newSession.user;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = _error(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // PROFILE HANDLING
  // ============================================================
  Future<void> fetchProfile() async {
    if (user == null) return;

    try {
      final result = await _supabase
          .from("profiles")
          .select()
          .eq("id", user!.id)
          .maybeSingle();

      profile = result != null ? Map<String, dynamic>.from(result) : null;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      profile = null;
      errorMessage = _error(e);

      if (kDebugMode) {
        print("[AuthProvider] fetchProfile error: $errorMessage");
      }

      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (user == null) throw Exception("No user signed in");

    _setLoading(true);
    try {
      await _supabase.from("profiles").upsert({
        "id": user!.id,
        ...data,
      });

      await fetchProfile();
      errorMessage = null;
    } catch (e) {
      errorMessage = _error(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UTILITIES
  // ============================================================
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String _error(Object e) {
    if (e is AuthException) return e.message;
    if (e is PostgrestException) return e.message;
    return e.toString();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
