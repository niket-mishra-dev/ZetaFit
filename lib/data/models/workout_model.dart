class WorkoutModel {
  final int id;
  final String name;
  final int? categoryId;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? equipment;
  final String? targetMuscle;
  final int? reps;
  final int? sets;
  final int? timeInSeconds;

  WorkoutModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.equipment,
    this.targetMuscle,
    this.reps,
    this.sets,
    this.timeInSeconds,
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] as int,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      equipment: map['equipment'] as String?,
      targetMuscle: map['target_muscle'] as String?,
      reps: map['reps'] as int?,
      sets: map['sets'] as int?,
      timeInSeconds: map['time_in_seconds'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'equipment': equipment,
      'target_muscle': targetMuscle,
      'reps': reps,
      'sets': sets,
      'time_in_seconds': timeInSeconds,
    };
  }
}
