import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'exercise_model.dart'; // Import your ExerciseModel
import 'package:workout_logger/exercise.dart';
import 'fitness_app_theme.dart';


class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  bool _isLoading = false;
  final List<String> muscleGroups = ['Biceps', 'Triceps', 'Chest', 'Shoulders', 'Lats', 'Calves', 'Shoulders', 'Abs','Quads','Hamstrings','Glutes'];

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
              backgroundColor: FitnessAppTheme.background,
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
              color: FitnessAppTheme.background,
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
                          Provider.of<ExerciseModel>(context, listen: false).addExercise(selectedExercise);
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
    final String baseUrl = Platform.isAndroid ? 'https://jaybird-exciting-merely.ngrok-free.app' : 'http://localhost:8000';
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
      backgroundColor: FitnessAppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showWorkoutExercises,
        backgroundColor: FitnessAppTheme.white,
        foregroundColor: FitnessAppTheme.background,
        child: _isLoading ? CircularProgressIndicator() : const Icon(Icons.add),
      ),
      body: Consumer<ExerciseModel>(
        builder: (context, model, child) {
          return Center(
            child: model.selectedExercises.isEmpty
                ? Text(
                    'No exercises selected',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  )
                : ListView.builder(
                    itemCount: model.selectedExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = model.selectedExercises[index];
                      return _ExerciseTile(exercise: exercise);
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _WorkoutExercisesList extends StatelessWidget {
  final List<Exercise> exercises;
  final Function(Exercise) onExerciseSelected;

  const _WorkoutExercisesList({required this.exercises, required this.onExerciseSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Number of cards per row
        crossAxisSpacing: 16.0, // Increased space between cards horizontally
        mainAxisSpacing: 16.0, // Increased space between cards vertically
        childAspectRatio: 1, // Adjusted to make the box more square
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return GestureDetector(
          onTap: () => onExerciseSelected(exercise),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 3, 3, 3), Color.fromARGB(255, 36, 36, 36)], // Fancy gradient background
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30), // Increased corner radius for a smoother look
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6), // Dark shadow for depth
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
                BoxShadow(
                  color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.3), // Glowing shadow effect
                  blurRadius: 2,
                  spreadRadius: 0.1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2), // Thin white border for a more defined look
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20), // Rounded corners for the image container
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1), // Inner shadow for a subtle glow
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20), // Clip the image to the rounded container
                        child: Stack(
                          children: [
                            Image.network(
                              exercise.images.isNotEmpty ? exercise.images[0] : '',
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
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


class _ExerciseTile extends StatefulWidget {
  final Exercise exercise;

  const _ExerciseTile({required this.exercise});

  @override
  State<_ExerciseTile> createState() => __ExerciseTileState();
}

class __ExerciseTileState extends State<_ExerciseTile> {
  List<Map<String, String>> sets = [];
  List<TextEditingController> repsControllers = [];
  List<TextEditingController> weightControllers = [];

  @override
  void initState() {
    super.initState();
    final model = Provider.of<ExerciseModel>(context, listen: false);
    sets = model.getSets(widget.exercise.name);

    // Initialize the controllers and set initial values
    for (var set in sets) {
      repsControllers.add(TextEditingController(text: set['reps']));
      weightControllers.add(TextEditingController(text: set['weight']));
    }

    // Add 1 set by default if no sets exist
    if (sets.isEmpty) {
      _addSet();
    }
  }

  void _addSet() {
    setState(() {
      sets.add({'reps': '', 'weight': ''});
      repsControllers.add(TextEditingController());
      weightControllers.add(TextEditingController());
      Provider.of<ExerciseModel>(context, listen: false).updateSets(widget.exercise.name, sets);
    });
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    for (var controller in repsControllers) {
      controller.dispose();
    }
    for (var controller in weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: FitnessAppTheme.background.withOpacity(0.1),
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
                        controller: repsControllers[index],
                        onChanged: (value) {
                          sets[index]['reps'] = value;
                          Provider.of<ExerciseModel>(context, listen: false).updateSets(widget.exercise.name, sets);
                        },
                      ),
                    ),
                    SizedBox(width: 10),
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
                        controller: weightControllers[index],
                        onChanged: (value) {
                          sets[index]['weight'] = value;
                          Provider.of<ExerciseModel>(context, listen: false).updateSets(widget.exercise.name, sets);
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