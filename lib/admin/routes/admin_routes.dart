import 'package:fitmor/admin/screens/admin_dashboard_screen.dart';
import 'package:fitmor/admin/screens/admin_login_screen.dart';
import 'package:fitmor/admin/screens/bot_answer_editor_screen.dart';
import 'package:fitmor/admin/screens/bot_answer_list_screen.dart';
import 'package:fitmor/admin/screens/bot_inbox_screen.dart';
import 'package:fitmor/admin/screens/broadcast_notification_screen.dart';
import 'package:fitmor/admin/screens/users_screen.dart';
import 'package:fitmor/admin/screens/workout_analytics_screen.dart';
import 'package:flutter/material.dart';

/// All admin routes must start with `/admin`
/// This avoids collision with user routes
class AdminRoutes {
  // 🔐 AUTH
  static const login = '/admin/login';

  // 🧭 CORE
  static const dashboard = '/admin/dashboard';

  // 🤖 BOT
  static const botInbox = '/admin/bot/inbox';
  static const botKnowledge = '/admin/bot/knowledge';
  static const botAnswerEditor = '/admin/bot/editor';

  // 📣 NOTIFICATIONS
  static const broadcast = '/admin/broadcast';

  // 👥 USERS
  static const users = '/admin/users';
  static const userDetail = '/admin/users/detail';

  // 📊 ANALYTICS
  static const analytics = '/admin/analytics';
}

class AdminAppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      // --------------------------------------------------
      // 🔐 AUTH
      // --------------------------------------------------
      case AdminRoutes.login:
        return _page(const AdminLoginScreen());

      // --------------------------------------------------
      // 🧭 CORE
      // --------------------------------------------------
      case AdminRoutes.dashboard:
        return _page(const AdminDashboardScreen());

      // --------------------------------------------------
      // 🤖 BOT
      // --------------------------------------------------
      case AdminRoutes.botInbox:
        return _page(const BotInboxScreen());

      case AdminRoutes.botKnowledge:
        return _page(const BotAnswerListScreen());

      case AdminRoutes.botAnswerEditor:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return _error('Missing editor arguments');

        return _page(
          BotAnswerEditorScreen(
            questionId: args['id'],
            question: args['question'],
          ),
        );

      // --------------------------------------------------
      // 📣 NOTIFICATIONS
      // --------------------------------------------------
      case AdminRoutes.broadcast:
        return _page(const BroadcastNotificationScreen());

      // --------------------------------------------------
      // 👥 USERS
      // --------------------------------------------------
      case AdminRoutes.users:
        return _page(const UserListScreen());

      // --------------------------------------------------
      // 📊 ANALYTICS
      // --------------------------------------------------
      case AdminRoutes.analytics:
        return _page(const WorkoutAnalyticsScreen());

      // --------------------------------------------------
      // ❌ FALLBACK
      // --------------------------------------------------
      default:
        return _error(settings.name);
    }
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

  static MaterialPageRoute _error(String? route) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Admin Routing Error')),
        body: Center(
          child: Text(
            'No admin route defined for:\n$route',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AdminRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case AdminRoutes.login:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('No route defined for this path')),
          ),
        );
    }
  }
}
