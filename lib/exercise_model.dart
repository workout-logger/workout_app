import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:workout_logger/exercise.dart';



class ExerciseModel extends ChangeNotifier {
  Map<String, List<Map<String, String>>> _exerciseSets = {};

  // Getter to return a list of selected exercises
  List<Exercise> get selectedExercises {
    return _exerciseSets.keys.map((exerciseName) {
      // Assuming you have a method to retrieve Exercise objects by their name
      return _getExerciseByName(exerciseName);
    }).toList();
  }

  Map<String, List<Map<String, String>>> get exerciseSets => _exerciseSets;

  ExerciseModel() {
    _loadExerciseSets();
  }

  void addExercise(Exercise exercise) {
    if (!_exerciseSets.containsKey(exercise.name)) {
      _exerciseSets[exercise.name] = [{'reps': '', 'weight': ''}];
      _saveExerciseSets();
      notifyListeners();
    }
  }

  void updateSets(String exerciseName, List<Map<String, String>> sets) {
    _exerciseSets[exerciseName] = sets;
    _saveExerciseSets();
    notifyListeners();
  }

  List<Map<String, String>> getSets(String exerciseName) {
    return _exerciseSets[exerciseName] ?? [];
  }

  void _loadExerciseSets() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSets = prefs.getString('exerciseSets');
    if (savedSets != null) {
      _exerciseSets = Map<String, List<Map<String, String>>>.from(
        json.decode(savedSets).map(
          (key, value) => MapEntry(key, List<Map<String, String>>.from(value)),
        ),
      );
      notifyListeners();
    }
  }

  void _saveExerciseSets() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('exerciseSets', json.encode(_exerciseSets));
  }

  // Dummy method to return an Exercise by its name
  Exercise _getExerciseByName(String name) {
    // You should replace this with your actual implementation
    // For example, fetching from a list of exercises or an API
    return Exercise(name: name, description: '', equipment: null, images: []);
  }
}
