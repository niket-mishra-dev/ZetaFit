import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_coach_service.dart';

class AIRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AICoachService _coachService = AICoachService();

  Future<String> generateAICoaching({
    required String userPrompt,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    // ================================
    // 1️⃣ FETCH USER PROFILE
    // ================================
    final profileResp = await _supabase
        .from("profiles")
        .select()
        .eq("id", user.id)
        .maybeSingle();

    final Map<String, dynamic> userProfile =
        profileResp == null ? {} : Map<String, dynamic>.from(profileResp);

    // ================================
    // 2️⃣ FETCH WORKOUT HISTORY
    // ================================
    final history = await _supabase
        .from("user_workout_history")
        .select("duration_seconds, completed_at")
        .eq("user_id", user.id);

    int totalSeconds = 0;
    DateTime? lastWorkout;

    for (final row in history) {
      final seconds = row["duration_seconds"];
      if (seconds is int) {
        totalSeconds += seconds;
      }

      final completedAt = row["completed_at"];
      if (completedAt != null) {
        final dt = DateTime.tryParse(completedAt.toString());
        if (dt != null &&
            (lastWorkout == null || dt.isAfter(lastWorkout))) {
          lastWorkout = dt;
        }
      }
    }

    final int totalWorkouts = history.length;
    final double caloriesBurned = totalSeconds * 0.14;

    final Map<String, dynamic> workoutStats = {
      "totalWorkouts": totalWorkouts,
      "totalDurationSeconds": totalSeconds,
      "avgWorkoutDuration":
          totalWorkouts == 0 ? 0 : totalSeconds / totalWorkouts,
      "caloriesBurned": caloriesBurned,
      "lastWorkoutDate": lastWorkout?.toIso8601String(),
    };

    // ================================
    // 3️⃣ CALL AI COACH SERVICE
    // ================================
    return _coachService.generateAdvice(
      userProfile: userProfile,
      workoutStats: workoutStats,
      userPrompt: userPrompt,
    );
  }
}
