import 'package:flutter/material.dart';
import 'exercise.dart';

class ExerciseModel extends ChangeNotifier {
  List<Exercise> _selectedExercises = [];

  List<Exercise> get selectedExercises => _selectedExercises;

  // Add this method to set exercises
  void setExercises(List<Exercise> exercises) {
    _selectedExercises = exercises;
    notifyListeners();
  }

  // Existing method to add an exercise
  void addExercise(Exercise exercise) {
    _selectedExercises.add(exercise);
    notifyListeners();
  }
}
