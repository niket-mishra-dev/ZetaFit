import 'package:fitmor/ai/prompts/ai_coach_screen.dart';
import 'package:fitmor/presentation/screens/home/home_screen.dart';
import 'package:fitmor/presentation/screens/notifications/notification_screen.dart';
import 'package:fitmor/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:fitmor/presentation/screens/plans/plan_details_screen.dart';
import 'package:fitmor/presentation/screens/plans/plan_screen.dart';
import 'package:fitmor/presentation/screens/profile/edit_profile_screen.dart';
import 'package:fitmor/presentation/screens/profile/profile_screen.dart';
import 'package:fitmor/presentation/screens/workouts/recent_activities.dart';
import 'package:fitmor/presentation/screens/workouts/workout_detail_screen.dart';
import 'package:fitmor/presentation/screens/workouts/workouts_screen.dart';
import 'package:flutter/material.dart';

class RouteNames {
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

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.root:
      case RouteNames.home:
        return _page(const HomeScreen());

      case RouteNames.workouts:
        return _page(const WorkoutsScreen());

      case RouteNames.workoutDetail:
        final int workoutId = settings.arguments as int;

        return _page(WorkoutDetailScreen(workoutId: workoutId));

      case RouteNames.recentActivity:
        return _page(const RecentActivityScreen());

      case RouteNames.plans:
        return _page(const PlanScreen());

      case RouteNames.planDetail:
        final plan = settings.arguments as Map<String, dynamic>?;
        if (plan == null) {
          return _error('Plan data missing');
        }
        return _page(PlanDetailScreen(plan: plan));

      case RouteNames.profile:
        return _page(const ProfileScreen());

      case RouteNames.editProfile:
        return _page(const EditProfileScreen());

      case RouteNames.aiCoach:
        return _page(const AICoachScreen());

      case RouteNames.onboarding:
        return _page(const OnboardingScreen());

      case RouteNames.progress:
        return _simplePage('Progress');

      case RouteNames.settings:
        return _simplePage('Settings');

      case RouteNames.notifications:
        return _page(const NotificationScreen());

      case RouteNames.help:
        return _simplePage('Help & Support');

      case RouteNames.about:
        return _simplePage('About');

      case RouteNames.terms:
        return _simplePage('Terms & Conditions');

      case RouteNames.privacy:
        return _simplePage('Privacy Policy');

      case RouteNames.faqs:
        return _simplePage('FAQs');

      case RouteNames.contact:
        return _simplePage('Contact Us');

      case RouteNames.feedback:
        return _simplePage('Feedback');

      case RouteNames.logout:
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
