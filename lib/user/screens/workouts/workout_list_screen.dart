import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'workout_detail_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  final int categoryId;
  final String title;

  const WorkoutListScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> workouts = [];
  Set<int> completedWorkoutIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadWorkouts(), _loadCompletedWorkouts()]);

    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadWorkouts() async {
    final data = await supabase
        .from('workouts')
        .select()
        .eq('category_id', widget.categoryId);

    workouts = (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _loadCompletedWorkouts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final rows = await supabase
        .from('user_workout_history')
        .select('workout_id')
        .eq('user_id', user.id);

    completedWorkoutIds = rows.map<int>((e) => e['workout_id'] as int).toSet();
  }

  String _durationText(Map w) {
    if (w['sets'] != null && w['reps'] != null) {
      return "${w['sets']} sets • ${w['reps']} reps";
    }
    if (w['time_in_seconds'] != null) {
      final min = (w['time_in_seconds'] / 60).round();
      return "$min min";
    }
    return "Quick workout";
  }

  String _difficultyHint(Map w) {
    final sets = w['sets'] ?? 1;
    if (sets <= 2) return "Easy";
    if (sets <= 4) return "Moderate";
    return "Hard";
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: GoogleFonts.michroma())),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : workouts.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final w = workouts[index];
                final completed = completedWorkoutIds.contains(w['id']);
                return _workoutTile(context, w, completed);
              },
            ),
    );
  }

  Widget _workoutTile(BuildContext context, Map item, bool completed) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workoutId: item['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? Colors.green.withOpacity(0.4)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                item['image_url'],
                width: 110,
                height: 95,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _durationText(item),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      _pill(_difficultyHint(item)),
                      const SizedBox(width: 6),
                      if (completed) _pill("Completed", success: true),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {bool success = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.15)
            : Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: success ? Colors.green : Colors.blue,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        "No workouts available yet",
        style: GoogleFonts.montserrat(fontSize: 14),
      ),
    );
  }
}
