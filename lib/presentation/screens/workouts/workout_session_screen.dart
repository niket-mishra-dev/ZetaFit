import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Map<String, dynamic> workout;

  const WorkoutSessionScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final supabase = Supabase.instance.client;

  late int totalSets;
  late int reps;
  late int durationSeconds;

  int currentSet = 1;
  bool isResting = false;
  bool isPaused = false;
  bool hasLoggedWorkout = false;

  int restSeconds = 30;
  Timer? _timer;

  // ------------------------------------------------
  // AI COACHING PHRASES
  // ------------------------------------------------
  final List<String> coachingTips = [
    "Breathe out on effort — stay controlled.",
    "Brace your core and protect your spine.",
    "Quality reps matter more than speed.",
    "Stay relaxed, power comes from control.",
    "Strong finish — you’re building discipline 💪",
  ];

  @override
  void initState() {
    super.initState();
    totalSets = widget.workout['sets'] ?? 1;
    reps = widget.workout['reps'] ?? 0;
    durationSeconds = widget.workout['time_in_seconds'] ?? 0;
  }

  // ------------------------------------------------
  // CONTEXTUAL AI COACH MESSAGE
  // ------------------------------------------------
  String _coachMessage() {
    if (isResting) {
      return "🧠 Recover now — deep breaths, prepare for next set.";
    }
    if (currentSet == 1) {
      return "🔥 Start strong. Focus on form, not speed.";
    }
    if (currentSet == totalSets) {
      return "💪 Final set! Give controlled maximum effort.";
    }
    return coachingTips[currentSet % coachingTips.length];
  }

  // ------------------------------------------------
  // REST TIMER
  // ------------------------------------------------
  void _startRest() {
    if (isPaused) return;

    setState(() => isResting = true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (isPaused) return;

      if (restSeconds <= 1) {
        t.cancel();
        setState(() {
          restSeconds = 30;
          isResting = false;
          currentSet++;
        });
      } else {
        setState(() => restSeconds--);
      }
    });
  }

  // ------------------------------------------------
  // PAUSE / RESUME
  // ------------------------------------------------
  void _togglePause() {
    setState(() => isPaused = !isPaused);
  }

  // ------------------------------------------------
  // FINISH WORKOUT (SAFE LOGGING)
  // ------------------------------------------------
  Future<void> _finishWorkout() async {
    if (hasLoggedWorkout) return;

    _timer?.cancel();
    hasLoggedWorkout = true;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_workout_history').insert({
      "user_id": user.id,
      "workout_id": widget.workout['id'],
      "completed_at": DateTime.now().toIso8601String(),
      "duration_seconds": durationSeconds,
      "reps_completed": reps,
      "sets_completed": totalSets,
    });

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🎉 Workout completed! Streak protected."),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentSet - 1) / totalSets;

    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Exit Workout?"),
            content: const Text(
              "Exiting now will cancel this session. Your progress won’t be saved.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Stay"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Exit"),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workout['name'], style: GoogleFonts.michroma()),
          actions: [
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // PROGRESS BAR
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(height: 20),

              Text(
                "Set $currentSet of $totalSets",
                style: GoogleFonts.montserrat(fontSize: 22),
              ),

              const SizedBox(height: 24),

              // MAIN DISPLAY
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isResting
                    ? Text(
                        "Rest: $restSeconds sec",
                        key: const ValueKey("rest"),
                        style: GoogleFonts.montserrat(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      )
                    : Text(
                        reps > 0 ? "$reps reps" : "$durationSeconds sec",
                        key: const ValueKey("work"),
                        style: GoogleFonts.montserrat(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // AI COACH PANEL
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _coachMessage(),
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ACTION BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPaused
                      ? null
                      : () {
                          if (currentSet < totalSets) {
                            _startRest();
                          } else {
                            _finishWorkout();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    currentSet < totalSets
                        ? "Complete Set"
                        : "Finish Workout",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
