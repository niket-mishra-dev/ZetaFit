import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AICoachService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =================================================
  // MAIN ENTRY
  // =================================================
  Future<String> generateAdvice({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> workoutStats,
    String? userPrompt,
  }) async {
    final input = (userPrompt ?? "").trim().toLowerCase();
    if (input.isEmpty) return _withConfidence(_fallback(), 0.40);

    if (kDebugMode) debugPrint("🧠 Coach input: $input");

    // 1️⃣ Fast deterministic rules
    final ruleReply = _ruleBasedResponse(input);
    if (ruleReply != null) {
      return _withConfidence(ruleReply, 0.95);
    }

    // 2️⃣ Assemble personalized plan
    final assembled = _tryAssemblePlan(
      input: input,
      profile: userProfile,
      stats: workoutStats,
    );
    if (assembled != null) return assembled;

    // 3️⃣ Knowledge base lookup
    final kbReply = await _searchKnowledgeBase(input);
    if (kbReply != null) {
      return _withConfidence(kbReply, 0.80);
    }

    // 4️⃣ Profile + stats based advice
    final contextualReply =
        _profileBasedAdvice(userProfile, workoutStats);
    if (contextualReply != null) {
      return _withConfidence(contextualReply, 0.85);
    }

    // 5️⃣ Learning loop
    await _storeUnknownQuestion(input);

    // 6️⃣ Fallback
    return _withConfidence(_fallback(), 0.40);
  }

  // =================================================
  // RULE-BASED RESPONSES (FAST PATH)
  // =================================================
  String? _ruleBasedResponse(String input) {
    if (input.contains("upper") && input.contains("workout")) {
      return '''
🔥 20-Minute Upper-Body Workout

• Push-ups – 3×12  
• Pike push-ups – 3×10  
• Chair dips – 3×12  
• Plank – 40 sec × 3  

Rest 30 seconds between sets.
''';
    }

    if (input.contains("stretch")) {
      return '''
🧘 5-Minute Morning Stretch

• Neck rolls – 30 sec  
• Shoulder circles – 30 sec  
• Hamstring stretch – 30 sec  
• Cat–cow – 10 reps
''';
    }

    if (input.contains("knee")) {
      return '''
🦵 Knee-Safe Training Advice

• Avoid jumping & deep squats  
• Prefer chair squats & wall sits  
• Glute bridges – 12 reps  
• Stretch hamstrings daily
''';
    }

    if (input.contains("diet") || input.contains("meal")) {
      return '''
🥗 Post-Workout Meal (400–500 kcal)

• Protein: Paneer / Eggs / Chicken  
• Carbs: Roti / Brown rice  
• Veggies + curd  
• Adequate hydration
''';
    }

    return null;
  }

  // =================================================
  // AUTOMATIC PLAN ASSEMBLY (EXPERT SYSTEM)
  // =================================================
  String? _tryAssemblePlan({
    required String input,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> stats,
  }) {
    final bool beginner =
        input.contains("beginner") ||
        (stats["totalWorkouts"] is int &&
            stats["totalWorkouts"] == 0);

    final bool fatLoss =
        input.contains("fat") || input.contains("weight");

    final bool noEquipment =
        input.contains("home") || input.contains("no equipment");

    final bool kneePain = input.contains("knee");
    final bool shortTime =
        input.contains("busy") || input.contains("short");

    int signals = 0;
    if (beginner) signals++;
    if (fatLoss) signals++;
    if (noEquipment) signals++;
    if (kneePain) signals++;
    if (shortTime) signals++;

    if (signals < 2) return null;

    final buffer = StringBuffer();
    buffer.writeln("📅 Personalized Workout Plan\n");

    // Frequency
    buffer.writeln(
      beginner
          ? "• Train 3 days per week"
          : "• Train 4–5 days per week",
    );

    // Goal
    buffer.writeln(
      fatLoss
          ? "• Focus on fat loss using strength + walking"
          : "• Focus on progressive strength training",
    );

    // Equipment
    buffer.writeln(
      noEquipment
          ? "• Bodyweight exercises only"
          : "• Use available equipment",
    );

    // Injury logic
    if (kneePain) {
      buffer.writeln("• Avoid jumping & deep squats");
      buffer.writeln("• Use chair squats & glute bridges");
    }

    // Time constraint
    if (shortTime) {
      buffer.writeln("• Keep workouts 20–30 minutes");
    }

    // Recovery
    buffer.writeln("\n🧘 Recovery & Lifestyle:");
    buffer.writeln("• Stretch after workouts");
    buffer.writeln("• Sleep 7–9 hours nightly");

    final confidence = _calculateConfidence(signals);
    return _withConfidence(buffer.toString(), confidence);
  }

  // =================================================
  // KNOWLEDGE BASE SEARCH (TAG MATCHING)
  // =================================================
  Future<String?> _searchKnowledgeBase(String input) async {
    try {
      final words =
          input.split(RegExp(r'\s+')).map((w) => w.trim()).toSet();

      final rows =
          await _supabase.from("bot_knowledge").select("answer, tags");

      for (final row in rows) {
        final tags = List<String>.from(row["tags"] ?? []);
        for (final tag in tags) {
          if (words.contains(tag.toLowerCase())) {
            return row["answer"];
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Knowledge search error: $e");
      }
    }
    return null;
  }

  // =================================================
  // PROFILE + STATS BASED ADVICE
  // =================================================
  String? _profileBasedAdvice(
    Map<String, dynamic> profile,
    Map<String, dynamic> stats,
  ) {
    final totalWorkouts = stats["totalWorkouts"];
    final calories = stats["caloriesBurned"];
    final lastWorkout = stats["lastWorkoutDate"];

    if (totalWorkouts is int && totalWorkouts == 0) {
      return '''
🚀 Welcome to your fitness journey!

Start with 15–20 minute workouts.
Focus on form and habit building.
Consistency beats intensity.
''';
    }

    if (calories is num && calories > 600) {
      return '''
🔥 Great work today!

You burned a good amount of calories.
Prioritize recovery:
• Stretching
• Protein intake
• Quality sleep
''';
    }

    if (lastWorkout == null && totalWorkouts is int && totalWorkouts > 0) {
      return '''
⏳ It looks like you’ve missed a few workouts.

Restart gently:
• Light full-body workout
• Short walk
• Stretching

Momentum comes back quickly 💪
''';
    }

    return null;
  }

  // =================================================
  // CONFIDENCE SYSTEM
  // =================================================
  double _calculateConfidence(int signals) {
    if (signals <= 1) return 0.55;
    if (signals == 2) return 0.70;
    if (signals == 3) return 0.85;
    return 0.95;
  }

  String _withConfidence(String text, double confidence) {
    final percent = (confidence * 100).toInt();
    return "$text\n\n🔍 Confidence: $percent%";
  }

  // =================================================
  // LEARNING LOOP
  // =================================================
  Future<void> _storeUnknownQuestion(String input) async {
    try {
      await _supabase.from("bot_unknown_questions").insert({
        "question": input,
        "created_at": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("⚠️ Failed to store unknown question: $e");
      }
    }
  }

  // =================================================
  // FALLBACK
  // =================================================
  String _fallback() {
    return '''
🤖 I’m still learning!

You can ask me about:
• Workouts & exercises
• Diet & nutrition
• Injury-safe training
• Weekly plans

I’ll keep improving over time 💡
''';
  }
}
