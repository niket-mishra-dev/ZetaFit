import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppState extends ChangeNotifier {
  bool _isAdmin = false;
  bool _initialized = false;

  bool get isAdmin => _isAdmin;
  bool get isReady => _initialized;

  /// 🔁 Called ONCE at app startup
  Future<void> initialize() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _markUser();
      return;
    }

    try {
      final admin = await Supabase.instance.client
          .from('admin_users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      _isAdmin = admin != null;
    } catch (_) {
      _isAdmin = false;
    }

    _initialized = true;
    notifyListeners();
  }

  /// 🟢 Explicit admin
  void markAdmin() {
    _isAdmin = true;
    _initialized = true;
    notifyListeners();
  }

  /// 🔵 Explicit user
  void markUser() {
    _markUser();
  }

  void _markUser() {
    _isAdmin = false;
    _initialized = true;
    notifyListeners();
  }

  /// 🔴 Logout cleanup
  void reset() {
    _isAdmin = false;
    _initialized = false;
    notifyListeners();
  }
}
