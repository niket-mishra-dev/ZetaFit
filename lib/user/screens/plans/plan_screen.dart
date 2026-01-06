import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../workouts/workout_session_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  Map<String, dynamic>? activePlan;
  List<Map<String, dynamic>> planDays = [];

  int todayDayNumber = 1;
  bool isRestDay = false;
  bool missedDay = false;

  List<Map<String, dynamic>> todayWorkouts = [];

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  // ------------------------------------------------------------
  // LOAD PLAN + DAY LOGIC
  // ------------------------------------------------------------
  Future<void> _loadPlan() async {
    setState(() => loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1️⃣ Get active plan (simplest: latest plan)
      activePlan = await supabase
          .from('plans')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (activePlan == null) {
        setState(() => loading = false);
        return;
      }

      // 2️⃣ Load plan days
      planDays = await supabase
          .from('plan_days')
          .select()
          .eq('plan_id', activePlan!['id'])
          .order('day_number');

      // 3️⃣ Detect today day number based on workout history
      final history = await supabase
          .from('user_workout_history')
          .select('completed_at')
          .eq('user_id', user.id)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (history != null) {
        final lastDate = DateTime.parse(history['completed_at']);
        final diff = DateTime.now().difference(lastDate).inDays;

        if (diff > 1) {
          missedDay = true;
        }

        todayDayNumber = (diff <= 0)
            ? planDays.length
            : (planDays.length + diff).clamp(1, planDays.length);
      }

      // 4️⃣ Load today workouts
      final todayDay = planDays.firstWhere(
        (d) => d['day_number'] == todayDayNumber,
        orElse: () => {},
      );

      if (todayDay.isEmpty) {
        isRestDay = true;
      } else {
        final rows = await supabase
            .from('plan_day_workouts')
            .select('workouts(*)')
            .eq('plan_day_id', todayDay['id']);

        todayWorkouts =
            rows.map<Map<String, dynamic>>((r) => r['workouts']).toList();

        isRestDay = todayWorkouts.isEmpty;
      }
    } catch (e) {
      debugPrint("Plan screen error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Plan", style: GoogleFonts.michroma()),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : activePlan == null
              ? _noPlanView(theme)
              : _planView(theme),
    );
  }

  // ------------------------------------------------------------
  // NO PLAN
  // ------------------------------------------------------------
  Widget _noPlanView(ThemeData theme) {
    return Center(
      child: Text(
        "No active plan yet.\nAsk AI Coach to generate one.",
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(fontSize: 16),
      ),
    );
  }

  // ------------------------------------------------------------
  // PLAN VIEW
  // ------------------------------------------------------------
  Widget _planView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _planHeader(theme),
          const SizedBox(height: 20),
          _todayCard(theme),
          const SizedBox(height: 20),
          _dayList(theme),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------
  Widget _planHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activePlan!['name'],
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          activePlan!['description'] ?? '',
          style: GoogleFonts.montserrat(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TODAY CARD
  // ------------------------------------------------------------
  Widget _todayCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today • Day $todayDayNumber",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            missedDay
                ? "You missed a day — let’s ease back in."
                : isRestDay
                    ? "Rest & recovery day 🧘"
                    : "Workout day 💪",
            style: GoogleFonts.montserrat(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          if (!isRestDay)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkoutSessionScreen(workout: todayWorkouts.first),
                    ),
                  );
                },
                child: const Text("Start Today’s Workout"),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DAY LIST
  // ------------------------------------------------------------
  Widget _dayList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Plan Schedule",
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...planDays.map((d) {
          final day = d['day_number'];
          final isToday = day == todayDayNumber;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isToday
                  ? theme.colorScheme.primary.withOpacity(0.15)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  "Day $day",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isToday)
                  const Icon(Icons.today, size: 18)
                else
                  const Icon(Icons.check_circle_outline, size: 18),
              ],
            ),
          );
        }),
      ],
    );
  }
}
