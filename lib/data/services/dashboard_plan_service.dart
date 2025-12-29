import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPlanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns structured info for today's plan card
  Future<Map<String, dynamic>?> getTodayPlan() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // 1️⃣ Get active plan (simple version: latest plan)
    final plan = await _supabase
        .from('plans')
        .select()
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (plan == null) return null;

    final int planId = plan['id'];
    final int totalWeeks = plan['duration_in_weeks'] ?? 4;
    final int totalDays = totalWeeks * 7;

    // 2️⃣ Determine start date (first workout logged)
    final history = await _supabase
        .from('user_workout_history')
        .select('completed_at')
        .eq('user_id', user.id)
        .order('completed_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (history == null) {
      return {
        "state": "not_started",
        "message": "Your plan hasn’t started yet. Let’s begin today 💪",
        "plan": plan,
      };
    }

    final DateTime startDate =
        DateTime.parse(history['completed_at']).toLocal();

    final int dayX =
        DateTime.now().difference(startDate).inDays + 1;

    // 3️⃣ Missed / completed / rest detection
    if (dayX > totalDays) {
      return {
        "state": "completed",
        "message": "🎉 Plan completed! Ready for the next challenge?",
        "plan": plan,
      };
    }

    // Example rest rule: every 7th day
    if (dayX % 7 == 0) {
      return {
        "state": "rest",
        "day": dayX,
        "message": "🧘 Rest day — recovery builds strength.",
        "plan": plan,
      };
    }

    // 4️⃣ Fetch today’s workout
    final dayRow = await _supabase
        .from('plan_days')
        .select('id')
        .eq('plan_id', planId)
        .eq('day_number', dayX)
        .maybeSingle();

    if (dayRow == null) {
      return {
        "state": "missed",
        "day": dayX,
        "message": "You missed a day — today we ease you back in 💙",
        "plan": plan,
      };
    }

    final workouts = await _supabase
        .from('plan_day_workouts')
        .select('workouts(name, image_url, time_in_seconds)')
        .eq('plan_day_id', dayRow['id']);

    return {
      "state": "workout",
      "day": dayX,
      "plan": plan,
      "workouts": workouts,
    };
  }
}
