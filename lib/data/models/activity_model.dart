class Activity {
  final int historyId;
  final int workoutId;
  final String workoutName;
  final String? imageUrl;
  final int durationSeconds;
  final DateTime completedAt;

  Activity({
    required this.historyId,
    required this.workoutId,
    required this.workoutName,
    this.imageUrl,
    required this.durationSeconds,
    required this.completedAt,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    final workout = map['workouts'] as Map<String, dynamic>;

    return Activity(
      historyId: (map['id'] as num).toInt(),
      workoutId: (workout['id'] as num).toInt(),
      workoutName: workout['name'] ?? 'Workout',
      imageUrl: workout['image_url'],
      durationSeconds: (map['duration_seconds'] ?? 0) as int,
      completedAt: DateTime.parse(map['completed_at']),
    );
  }

  int get durationMinutes => (durationSeconds / 60).ceil();
}


class ActivityCache {
  static final List<Activity> _cached = [];

  static List<Activity> getAll() => List.unmodifiable(_cached);

  static void save(List<Activity> items) {
    _cached
      ..clear()
      ..addAll(items);
  }

  static void append(List<Activity> items) {
    _cached.addAll(items);
  }

  static void clear() => _cached.clear();
}
