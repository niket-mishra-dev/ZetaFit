import 'package:fitmor/admin/shell/admin_shell.dart';
import 'package:fitmor/core/state/app_state.dart';
import 'package:fitmor/user/screens/auth/login_screen.dart';
import 'package:fitmor/user/shell/user_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppGuard extends StatelessWidget {
  const AppGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final supabase = Supabase.instance.client;

    // ⏳ App not ready yet
    if (!appState.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ Not logged in
    if (supabase.auth.currentUser == null) {
      return LoginScreen();
    }

    // 🔐 Admin
    if (appState.isAdmin) {
      return const AdminShell();
    }

    // 👤 Normal user
    return const RootShell();
  }
}
