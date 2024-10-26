import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:workout_logger/exercise.dart';



class ExerciseModel extends ChangeNotifier {
  Map<String, List<Map<String, String>>> _exerciseSets = {};
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = "0:00";
  String get formattedTime => _formattedTime;



  void startTimer() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        _updateFormattedTime();
      });
      notifyListeners();
    }
  }

  // Pause the workout timer
  void pauseTimer() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      _saveTimerState();
      notifyListeners();
    }
  }

  // Reset the workout timer
  void resetTimer() {
    _stopwatch.reset();
    _formattedTime = "0:00";
    _timer?.cancel();
    _saveTimerState();
    notifyListeners();
  }

  // Convert stopwatch time to a readable format (MM:SS)
  void _updateFormattedTime() {
    final elapsed = _stopwatch.elapsed;
    _formattedTime = '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    notifyListeners();
  }

  // Load timer state from shared preferences
  void _loadTimerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? elapsedMilliseconds = prefs.getInt('workoutTimer');
    if (elapsedMilliseconds != null) {
      _stopwatch.start();
      _stopwatch.elapsedMilliseconds;  // restore elapsed time
      _updateFormattedTime();
    }
  }

  // Save the current timer state to shared preferences
  void _saveTimerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('workoutTimer', _stopwatch.elapsedMilliseconds);
  }

  List<Exercise> get selectedExercises {
    return _exerciseSets.keys.map((exerciseName) {
      return _getExerciseByName(exerciseName);
    }).toList();
  } 

  Map<String, List<Map<String, String>>> get exerciseSets => _exerciseSets;

  ExerciseModel() {
    _loadExerciseSets();
    _loadTimerState();

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
