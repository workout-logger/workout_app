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
                      return _WorkoutExercisesList(exercises: snapshot.data!);
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
    final String baseUrl = Platform.isAndroid ? 'http://10.0.0.70:8000' : 'http://localhost:8000';
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
        child: Text(
          'Workout Page',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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

  const _WorkoutExercisesList({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          color: Colors.white, // To contrast the white text
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
        );
      },
    );
  }
}
