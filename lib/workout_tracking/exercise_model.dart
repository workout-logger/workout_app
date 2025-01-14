// exercise_model.dart
import 'package:flutter/foundation.dart';
import 'exercise.dart';
import 'workout_set.dart';

class ExerciseModel extends ChangeNotifier {
  List<Exercise> _selectedExercises = [];

  List<Exercise> get selectedExercises => _selectedExercises;

  void setExercises(List<Exercise> exercises) {
    _selectedExercises = exercises;
    notifyListeners();
  }

  void addExercise(Exercise exercise) {
    // Ensure the new exercise starts with one set by default if it has no sets
    if (exercise.sets.isEmpty) {
      exercise.sets.add(WorkoutSet(reps: '', weight: ''));
    }
    _selectedExercises.add(exercise);
    notifyListeners();
  }

  void updateExerciseSets(int exerciseIndex, List<WorkoutSet> sets) {
    if (exerciseIndex >= 0 && exerciseIndex < _selectedExercises.length) {
      _selectedExercises[exerciseIndex].sets = sets;
      notifyListeners();
    } else {
      print('Invalid exercise index: $exerciseIndex');
    }
  }

  void deleteExercise(int exerciseIndex) {
    if (exerciseIndex >= 0 && exerciseIndex < _selectedExercises.length) {
      _selectedExercises.removeAt(exerciseIndex);
      notifyListeners();
    } else {
      print('Invalid exercise index for deletion: $exerciseIndex');
    }
  }

  void resetWorkout() {
    _selectedExercises = [];
    notifyListeners();
  }
}
