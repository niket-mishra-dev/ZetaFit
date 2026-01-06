import 'package:fitmor/user/screens/workouts/workout_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  bool workedOutToday = false;
  Map<String, dynamic>? workout;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadWorkout(), _checkTodayWorkout()]);
  }

  // --------------------------------------------------
  // LOAD WORKOUT
  // --------------------------------------------------
  Future<void> _loadWorkout() async {
    try {
      final data = await supabase
          .from('workouts')
          .select()
          .eq('id', widget.workoutId)
          .single();

      workout = Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint("❌ Error loading workout: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // CHECK IF USER ALREADY WORKED OUT TODAY
  // --------------------------------------------------
  Future<void> _checkTodayWorkout() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final rows = await supabase
        .from('user_workout_history')
        .select('id')
        .eq('user_id', user.id)
        .gte('completed_at', startOfDay.toIso8601String())
        .limit(1);

    workedOutToday = rows.isNotEmpty;
  }

  // --------------------------------------------------
  // SMART COACH MESSAGE
  // --------------------------------------------------
  String _coachIntro() {
    if (workedOutToday) {
      return "🧘 You’ve already trained today.\nThis workout is optional — focus on form and recovery.";
    }

    return "🔥 This workout will improve strength and consistency.\nTake it one set at a time.";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading || workout == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // --------------------------------------------------
            // MAIN CONTENT
            // --------------------------------------------------
            SingleChildScrollView(
              child: Column(
                children: [
                  // HERO IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    child: Image.network(
                      workout!["image_url"],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE
                        Text(
                          workout!["name"],
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // META INFO
                        Text(
                          "${workout!["reps"]} reps • ${workout!["sets"]} sets • ${workout!["time_in_seconds"]} sec",
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // AI COACH MESSAGE
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(
                              0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt, color: Colors.amber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _coachIntro(),
                                  style: GoogleFonts.montserrat(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // INSTRUCTIONS
                        Text(
                          "Instructions",
                          style: GoogleFonts.michroma(
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          workout!["description"] ??
                              "No description available.",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 26),

                        if (workout!["equipment"] != null)
                          _infoRow(
                            theme,
                            Icons.fitness_center,
                            "Equipment",
                            workout!["equipment"],
                          ),

                        const SizedBox(height: 12),

                        if (workout!["target_muscle"] != null)
                          _infoRow(
                            theme,
                            Icons.favorite,
                            "Target Muscle",
                            workout!["target_muscle"],
                          ),

                        const SizedBox(height: 40),

                        // START SESSION BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WorkoutSessionScreen(workout: workout!),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            label: Text(
                              workedOutToday ? "Start Anyway" : "Start Workout",
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Bottom spacing so button never hides
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // FLOATING BACK BUTTON
            // --------------------------------------------------
            Positioned(
              top: 18,
              left: 16,
              child: Material(
                color: Colors.black.withOpacity(0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          "$title: ",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
