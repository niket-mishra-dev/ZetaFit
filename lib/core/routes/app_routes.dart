import 'package:fitmor/admin/routes/admin_routes.dart';
import 'package:fitmor/user/routes/user_routes.dart';
import 'package:flutter/material.dart';

class AppRouter {

  static Route<dynamic> generate(RouteSettings settings) {
    if (settings.name!.startsWith('/admin')) {
      return AdminAppRoutes.generate(settings);
    }

    return UserRoutes.generateRoute(settings);
  }
}
