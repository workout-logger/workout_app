// workout_set.dart
class WorkoutSet {
  String reps;
  String weight;

  WorkoutSet({required this.reps, required this.weight});

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      reps: json['reps'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
    };
  }
}
