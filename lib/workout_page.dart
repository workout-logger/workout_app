import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  bool _isLoading = false;
  final List<String> muscleGroups = ['Biceps', 'Triceps', 'Back', 'Chest', 'Legs', 'Shoulders'];
  List<Exercise> _selectedExercises = [];

  void _showWorkoutExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DefaultTabController(
          length: muscleGroups.length,
          child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                indicatorColor: Colors.white,
                indicatorPadding: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                tabs: muscleGroups.map((muscle) => Tab(text: muscle)).toList(),
              ),
            ),
            body: Container(
              color: const Color.fromARGB(255, 0, 0, 0),
              child: TabBarView(
                children: muscleGroups.map((muscle) {
                  return FutureBuilder<List<Exercise>>(
                    future: _fetchWorkoutExercises(muscle),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No exercises found.'));
                      }
                      return _WorkoutExercisesList(
                        exercises: snapshot.data!,
                        onExerciseSelected: (selectedExercise) {
                          setState(() {
                            _selectedExercises.add(selectedExercise);
                          });
                          Navigator.of(context).pop(); // Close the bottom sheet after selection
                        },
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Exercise>> _fetchWorkoutExercises(String muscleType) async {
    final String baseUrl = Platform.isAndroid ? 'https://5548-2601-249-4300-56f0-f166-9de1-1bba-43b9.ngrok-free.app' : 'http://localhost:8000';
    final response = await http.get(Uri.parse('$baseUrl/exercise/?muscle_type=$muscleType'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Exercise.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load exercises: ${response.statusCode}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      floatingActionButton: FloatingActionButton(
        onPressed: _showWorkoutExercises,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.primary,
        child: _isLoading ? CircularProgressIndicator() : const Icon(Icons.add),
      ),
      body: Center(
        child: _selectedExercises.isEmpty
            ? Text(
                'No exercises selected',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              )
            : ListView.builder(
                itemCount: _selectedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _selectedExercises[index];
                  return _ExerciseTile(exercise: exercise);
                },
              ),
      ),
    );
  }
}

class Exercise {
  final String name;
  final String description;
  final String? equipment;
  final List<String> images;

  Exercise({
    required this.name,
    required this.description,
    this.equipment,
    required this.images,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      description: _removeHtmlTags(json['description']),
      equipment: json['equipment'],
      images: List<String>.from(json['images']),
    );
  }

  static String _removeHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }
}

class _WorkoutExercisesList extends StatelessWidget {
  final List<Exercise> exercises;
  final Function(Exercise) onExerciseSelected;

  const _WorkoutExercisesList({required this.exercises, required this.onExerciseSelected});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return GestureDetector(
          onTap: () => onExerciseSelected(exercise),
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.black),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(exercise.description),
                          const SizedBox(height: 8),
                          if (exercise.equipment != null)
                            Text('Equipment: ${exercise.equipment}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.network(
                        exercise.images.isNotEmpty ? exercise.images[0] : '',
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExerciseTile extends StatefulWidget {
  final Exercise exercise;

  const _ExerciseTile({required this.exercise});

  @override
  State<_ExerciseTile> createState() => __ExerciseTileState();
}

class __ExerciseTileState extends State<_ExerciseTile> {
  List<Map<String, String>> sets = [];

  void _addSet() {
    setState(() {
      sets.add({'reps': '', 'weight': ''});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...sets.map((set) {
              int index = sets.indexOf(set);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                          hintText: 'Enter reps',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                        onChanged: (value) {
                          sets[index]['reps'] = value;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Weight',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                          hintText: 'Enter weight',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                        onChanged: (value) {
                          sets[index]['weight'] = value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addSet,
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  'Add Set',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
