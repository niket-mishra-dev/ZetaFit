import 'package:fitmor/user/screens/ai/prompts/ai_coach_screen.dart';
import 'package:fitmor/user/screens/home/home_screen.dart';
import 'package:fitmor/user/screens/notifications/notification_screen.dart';
import 'package:fitmor/user/screens/onboarding/onboarding_screen.dart';
import 'package:fitmor/user/screens/plans/plan_details_screen.dart';
import 'package:fitmor/user/screens/plans/plan_screen.dart';
import 'package:fitmor/user/screens/profile/edit_profile_screen.dart';
import 'package:fitmor/user/screens/profile/profile_screen.dart';
import 'package:fitmor/user/screens/workouts/recent_activities.dart';
import 'package:fitmor/user/screens/workouts/workout_detail_screen.dart';
import 'package:fitmor/user/screens/workouts/workouts_screen.dart';
import 'package:flutter/material.dart';

class UserRouteNames {
  static const root = '/';
  static const home = '/home';

  static const workouts = '/workouts';
  static const workoutDetail = '/workout-detail';
  static const recentActivity = '/recent-activity';

  static const plans = '/plans';
  static const planDetail = '/plan-detail';

  static const profile = '/profile';
  static const editProfile = '/edit-profile';

  static const aiCoach = '/ai-coach';
  static const progress = '/progress';
  static const onboarding = '/onboarding';

  static const settings = '/settings';
  static const notifications = '/notifications';
  static const help = '/help';
  static const about = '/about';
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const faqs = '/faqs';
  static const contact = '/contact';
  static const feedback = '/feedback';
  static const logout = '/logout';

  // 🔐 Future-ready (even if not used yet)
  static const login = '/login';
  static const register = '/register';
}

class UserRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case UserRouteNames.root:
      case UserRouteNames.home:
        return _page(const HomeScreen());

      case UserRouteNames.workouts:
        return _page(const WorkoutsScreen());

      case UserRouteNames.workoutDetail:
        final int workoutId = settings.arguments as int;

        return _page(WorkoutDetailScreen(workoutId: workoutId));

      case UserRouteNames.recentActivity:
        return _page(const RecentActivityScreen());

      case UserRouteNames.plans:
        return _page(const PlanScreen());

      case UserRouteNames.planDetail:
        final plan = settings.arguments as Map<String, dynamic>?;
        if (plan == null) {
          return _error('Plan data missing');
        }
        return _page(PlanDetailScreen(plan: plan));

      case UserRouteNames.profile:
        return _page(const ProfileScreen());

      case UserRouteNames.editProfile:
        return _page(const EditProfileScreen());

      case UserRouteNames.aiCoach:
        return _page(const AICoachScreen());

      case UserRouteNames.onboarding:
        return _page(const OnboardingScreen());

      case UserRouteNames.progress:
        return _simplePage('Progress');

      case UserRouteNames.settings:
        return _simplePage('Settings');

      case UserRouteNames.notifications:
        return _page(const NotificationScreen());

      case UserRouteNames.help:
        return _simplePage('Help & Support');

      case UserRouteNames.about:
        return _simplePage('About');

      case UserRouteNames.terms:
        return _simplePage('Terms & Conditions');

      case UserRouteNames.privacy:
        return _simplePage('Privacy Policy');

      case UserRouteNames.faqs:
        return _simplePage('FAQs');

      case UserRouteNames.contact:
        return _simplePage('Contact Us');

      case UserRouteNames.feedback:
        return _simplePage('Feedback');

      case UserRouteNames.logout:
        return _simplePage('Logout');

      default:
        return _error('No route defined for ${settings.name}');
    }
  }

  // ---------- Helpers ----------

  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

  static MaterialPageRoute _simplePage(String title) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('$title Screen')),
      ),
    );
  }

  static MaterialPageRoute _error(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(body: Center(child: Text(message))),
    );
  }
}
