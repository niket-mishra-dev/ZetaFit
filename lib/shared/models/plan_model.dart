import 'workout_model.dart';

class PlanModel {
  final int id;
  final String name;
  final String? description;
  final String? level;
  final int durationInWeeks;
  final List<PlanDayModel> days;

  PlanModel({
    required this.id,
    required this.name,
    this.description,
    this.level,
    required this.durationInWeeks,
    required this.days,
  });

  factory PlanModel.fromMap(
    Map<String, dynamic> map,
    List<PlanDayModel> days,
  ) {
    return PlanModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      level: map['level'] as String?,
      durationInWeeks: map['duration_in_weeks'] as int,
      days: days,
    );
  }
}

class PlanDayModel {
  final int id;
  final int dayNumber;
  final List<PlanDayWorkoutModel> workouts;

  PlanDayModel({
    required this.id,
    required this.dayNumber,
    required this.workouts,
  });

  factory PlanDayModel.fromMap(
    Map<String, dynamic> map,
    List<PlanDayWorkoutModel> workouts,
  ) {
    return PlanDayModel(
      id: map['id'] as int,
      dayNumber: map['day_number'] as int,
      workouts: workouts,
    );
  }
}

class PlanDayWorkoutModel {
  final int id;
  final int orderNumber;
  final int? reps;
  final int? sets;
  final int? timeInSeconds;
  final WorkoutModel workout;

  PlanDayWorkoutModel({
    required this.id,
    required this.orderNumber,
    this.reps,
    this.sets,
    this.timeInSeconds,
    required this.workout,
  });

  factory PlanDayWorkoutModel.fromMap(
    Map<String, dynamic> map,
    WorkoutModel workout,
  ) {
    return PlanDayWorkoutModel(
      id: map['id'] as int,
      orderNumber: map['order_number'] as int,
      reps: map['reps'] as int?,
      sets: map['sets'] as int?,
      timeInSeconds: map['time_in_seconds'] as int?,
      workout: workout,
    );
  }
}
