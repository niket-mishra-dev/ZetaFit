import 'package:fitmor/admin/shell/admin_shell.dart';
import 'package:fitmor/admin/screens/admin_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const AdminLoginScreen();
    }

    return FutureBuilder(
      future: supabase
          .from('admin_users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          supabase.auth.signOut();
          return const AdminLoginScreen();
        }

        return const AdminShell();
      },
    );
  }
}
