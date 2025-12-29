import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../workouts/workout_session_screen.dart';

class PlanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plan;

  const PlanDetailScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> planDays = [];
  Map<int, List<Map<String, dynamic>>> dayWorkouts = {};

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  // ------------------------------------------------------------
  // LOAD PLAN DETAILS
  // ------------------------------------------------------------
  Future<void> _loadPlanDetails() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Load plan days
      planDays = await supabase
          .from('plan_days')
          .select()
          .eq('plan_id', widget.plan['id'])
          .order('day_number');

      // 2️⃣ Load workouts for each day
      for (final day in planDays) {
        final rows = await supabase
            .from('plan_day_workouts')
            .select('workouts(*)')
            .eq('plan_day_id', day['id']);

        dayWorkouts[day['day_number']] =
            rows.map<Map<String, dynamic>>((r) => r['workouts']).toList();
      }
    } catch (e) {
      debugPrint('PlanDetail error: $e');
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
        title: Text(
          widget.plan['name'],
          style: GoogleFonts.michroma(),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _content(theme),
    );
  }

  Widget _content(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _planHeader(theme),
          const SizedBox(height: 20),
          _schedule(theme),
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
          widget.plan['name'],
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.plan['description'] ?? '',
          style: GoogleFonts.montserrat(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Duration: ${widget.plan['duration_in_weeks']} weeks",
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // DAY SCHEDULE
  // ------------------------------------------------------------
  Widget _schedule(ThemeData theme) {
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

        ...planDays.map((day) {
          final dayNumber = day['day_number'];
          final workouts = dayWorkouts[dayNumber] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ExpansionTile(
              title: Text(
                "Day $dayNumber",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: workouts.isEmpty
                  ? [
                      Text(
                        "Rest day 🧘",
                        style: GoogleFonts.montserrat(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ]
                  : workouts.map((w) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          w['name'],
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "${w['time_in_seconds'] ?? 0} sec",
                          style: GoogleFonts.montserrat(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WorkoutSessionScreen(workout: w),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
            ),
          );
        }),
      ],
    );
  }
}
