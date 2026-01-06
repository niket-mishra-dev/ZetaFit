import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutAnalyticsScreen extends StatefulWidget {
  const WorkoutAnalyticsScreen({super.key});

  @override
  State<WorkoutAnalyticsScreen> createState() =>
      _WorkoutAnalyticsScreenState();
}

class _WorkoutAnalyticsScreenState
    extends State<WorkoutAnalyticsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = true;

  int totalUsers = 0;
  int totalWorkouts = 0;
  double totalMinutes = 0;
  int activeUsers = 0;
  double avgWorkoutMinutes = 0;

  // ===========================================================
  // ZETAFIT COLORS
  // ===========================================================
  static const Color primaryNeon = Color(0xFF00E5FF);
  static const Color neonPink = Color(0xFFFF2ED1);
  static const Color accentPurple = Color(0xFFB388FF);

  static const Color darkBg = Color(0xFF0D0D0F);
  static const Color darkCard = Color(0xFF1A1A1E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // -----------------------------------------------------------
  // LOAD ANALYTICS
  // -----------------------------------------------------------
  Future<void> _load() async {
    setState(() => loading = true);

    final users =
        await supabase.from('profiles').select('id');

    final workouts = await supabase
        .from('user_workout_history')
        .select('user_id, duration_seconds');

    totalUsers = users.length;
    totalWorkouts = workouts.length;

    double mins = 0;
    final Set<String> uniqueUsers = {};

    for (final w in workouts) {
      mins += ((w['duration_seconds'] ?? 0) as num) / 60;
      if (w['user_id'] != null) {
        uniqueUsers.add(w['user_id']);
      }
    }

    totalMinutes = mins;
    activeUsers = uniqueUsers.length;
    avgWorkoutMinutes =
        totalWorkouts == 0 ? 0 : totalMinutes / totalWorkouts;

    setState(() => loading = false);
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryNeon,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Text(
                      'Workout Analytics',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Platform performance overview',
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // STATS GRID
                    Row(
                      children: [
                        _statCard(
                          'Users',
                          totalUsers.toString(),
                          Icons.people_rounded,
                          primaryNeon,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Active',
                          activeUsers.toString(),
                          Icons.flash_on_rounded,
                          accentPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statCard(
                          'Workouts',
                          totalWorkouts.toString(),
                          Icons.fitness_center_rounded,
                          neonPink,
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Hours',
                          (totalMinutes / 60).toStringAsFixed(1),
                          Icons.timer_rounded,
                          primaryNeon,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // EXTRA METRICS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Metrics',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _metricRow(
                            'Avg workout duration',
                            '${avgWorkoutMinutes.toStringAsFixed(1)} min',
                          ),
                          _metricRow(
                            'Workouts per user',
                            totalUsers == 0
                                ? '0'
                                : (totalWorkouts / totalUsers)
                                    .toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ADMIN INSIGHT
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryNeon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primaryNeon.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _insightText(),
                        style: GoogleFonts.montserrat(
                          color: primaryNeon,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // -----------------------------------------------------------
  // STAT CARD
  // -----------------------------------------------------------
  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // METRIC ROW
  // -----------------------------------------------------------
  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // DYNAMIC INSIGHT
  // -----------------------------------------------------------
  String _insightText() {
    if (activeUsers == 0) {
      return 'No active users yet. Encourage onboarding workouts.';
    }

    if (avgWorkoutMinutes >= 30) {
      return 'Strong engagement detected 💪 Users are training consistently. Consider streak rewards.';
    }

    return 'Engagement is moderate. Motivational broadcasts could improve consistency.';
  }
}
