import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  int streakDays = 0;
  final Map<String, double> weeklyMinutes = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await Future.wait([
        _loadStreak(user.id),
        _loadWeekly(user.id),
      ]);
    } catch (e) {
      debugPrint("Progress error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // STREAK (consistency only — no duplication)
  // --------------------------------------------------
  Future<void> _loadStreak(String userId) async {
    final rows = await supabase
        .from('user_workout_history')
        .select('completed_at')
        .eq('user_id', userId);

    final uniqueDays = <String>{};

    for (final r in rows) {
      final dt = DateTime.tryParse(r['completed_at'].toString());
      if (dt != null) {
        uniqueDays.add("${dt.year}-${dt.month}-${dt.day}");
      }
    }

    streakDays = uniqueDays.length;
  }

  // --------------------------------------------------
  // WEEKLY TRAINING LOAD
  // --------------------------------------------------
  Future<void> _loadWeekly(String userId) async {
    weeklyMinutes.clear();
    final now = DateTime.now();

    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i)),
    );

    for (final d in days) {
      weeklyMinutes["${d.year}-${d.month}-${d.day}"] = 0;
    }

    final rows = await supabase
        .from('user_workout_history')
        .select('duration_seconds, completed_at')
        .eq('user_id', userId)
        .gte(
          'completed_at',
          now.subtract(const Duration(days: 7)).toIso8601String(),
        );

    for (final r in rows) {
      final dt = DateTime.tryParse(r['completed_at'].toString());
      if (dt == null) continue;

      final key = "${dt.year}-${dt.month}-${dt.day}";
      final secs = (r['duration_seconds'] ?? 0) as num;

      if (weeklyMinutes.containsKey(key)) {
        weeklyMinutes[key] =
            (weeklyMinutes[key] ?? 0) + secs / 60.0;
      }
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(theme),
                    const SizedBox(height: 28),

                    _trainingLoad(theme),
                    const SizedBox(height: 28),

                    _consistencyInsight(theme),
                    const SizedBox(height: 28),

                    _peakEffort(theme),
                    const SizedBox(height: 28),

                    _longTermNarrative(theme),
                  ],
                ),
              ),
            ),
    );
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------
  Widget _header(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Progress",
          style: GoogleFonts.michroma(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "A reflection of your discipline over time",
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // TRAINING LOAD (PRIMARY CHART)
  // --------------------------------------------------
  Widget _trainingLoad(ThemeData theme) {
    final keys = weeklyMinutes.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), weeklyMinutes[keys[i]] ?? 0));
    }

    final avg = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a + b) / spots.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Training Load",
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Consistency matters more than peaks",
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.22),
                              theme.colorScheme.secondary.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Average: ${avg.toStringAsFixed(1)} min / day",
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // CONSISTENCY INSIGHT
  // --------------------------------------------------
  Widget _consistencyInsight(ThemeData theme) {
    String text;

    if (streakDays == 0) {
      text = "You haven’t established a routine yet. Start small.";
    } else if (streakDays < 5) {
      text = "You’re building consistency. Protect this momentum.";
    } else if (streakDays < 10) {
      text = "You’re forming a real habit. This is where change happens.";
    } else {
      text = "Your consistency is elite. Few reach this stage.";
    }

    return _insightCard(
      theme,
      title: "Consistency",
      message: text,
      icon: Icons.timeline,
    );
  }

  // --------------------------------------------------
  // PEAK EFFORT
  // --------------------------------------------------
  Widget _peakEffort(ThemeData theme) {
    final bestDay = weeklyMinutes.values.isEmpty
        ? 0
        : weeklyMinutes.values.reduce((a, b) => a > b ? a : b);

    return _insightCard(
      theme,
      title: "Peak Effort",
      message: bestDay > 0
          ? "Your strongest day this week: ${bestDay.toStringAsFixed(0)} minutes."
          : "No peak recorded yet. Your first one is coming.",
      icon: Icons.emoji_events,
    );
  }

  // --------------------------------------------------
  // LONG TERM NARRATIVE
  // --------------------------------------------------
  Widget _longTermNarrative(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
      ),
      child: Text(
        "Progress isn’t about intensity — it’s about showing up. "
        "Every session compounds. Even the quiet days matter.",
        style: GoogleFonts.montserrat(
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SHARED INSIGHT CARD
  // --------------------------------------------------
  Widget _insightCard(
    ThemeData theme, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
