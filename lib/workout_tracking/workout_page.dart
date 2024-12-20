// workout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_tile.dart';
import 'exercise_model.dart';
import 'stopwatch_provider.dart';
import 'exercise.dart';
import '../fitness_app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:workout_logger/constants.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _workoutStarted = false;
  final List<Map<String, dynamic>> _muscleGroups = [
    {'name': 'Biceps', 'color': const Color(0xFFFF6B6B), 'icon': Icons.fitness_center},
    {'name': 'Triceps', 'color': const Color(0xFF4ECDC4), 'icon': Icons.fitness_center},
    {'name': 'Chest', 'color': const Color(0xFF45B7D1), 'icon': Icons.fitness_center},
    {'name': 'Shoulders', 'color': const Color(0xFF96CEB4), 'icon': Icons.fitness_center},
    {'name': 'Lats', 'color': const Color(0xFFFFEEAD), 'icon': Icons.fitness_center},
    {'name': 'Calves', 'color': const Color(0xFFD4A5A5), 'icon': Icons.fitness_center},
    {'name': 'Abs', 'color': const Color(0xFF9B786F), 'icon': Icons.fitness_center},
    {'name': 'Quads', 'color': const Color(0xFFA8E6CE), 'icon': Icons.fitness_center},
    {'name': 'Hamstrings', 'color': const Color(0xFFFF8C94), 'icon': Icons.fitness_center},
    {'name': 'Glutes', 'color': const Color(0xFFA6D1E6), 'icon': Icons.fitness_center},
  ];
  late StopwatchProvider stopwatchProvider;
  late ExerciseModel exerciseModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startWorkout();
    _loadWorkoutState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);
    exerciseModel = Provider.of<ExerciseModel>(context, listen: false);
  }

  @override
  void dispose() {
    _saveWorkoutState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveWorkoutState();
    } else if (state == AppLifecycleState.resumed) {
      _loadWorkoutState();
    }
  }

  Future<void> _saveWorkoutState() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('workoutStarted', _workoutStarted);
    prefs.setInt('elapsedMilliseconds', stopwatchProvider.elapsedMilliseconds);

    final exercisesJson =
        json.encode(exerciseModel.selectedExercises.map((e) => e.toJson()).toList());
    prefs.setString('selectedExercises', exercisesJson);
  }

  Future<void> _loadWorkoutState() async {
    final prefs = await SharedPreferences.getInstance();

    final savedWorkoutStarted = prefs.getBool('workoutStarted') ?? false;
    final savedElapsedMilliseconds = prefs.getInt('elapsedMilliseconds') ?? 0;

    if (savedWorkoutStarted) {
      setState(() {
        _workoutStarted = true;
      });
      stopwatchProvider.startStopwatch(initialMilliseconds: savedElapsedMilliseconds);
    }

    final exercisesJson = prefs.getString('selectedExercises');
    if (exercisesJson != null) {
      final exercisesList = (json.decode(exercisesJson) as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
      exerciseModel.setExercises(exercisesList);
    }

    setState(() {});
  }

  Future<void> _startWorkout() async {
    final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);
    setState(() {
      _workoutStarted = true;
      stopwatchProvider.startStopwatch();
    });
  }

  String _formattedTime(int elapsedMilliseconds) {
    final duration = Duration(milliseconds: elapsedMilliseconds);
    return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _showWorkoutExercises() async {
    setState(() => _isLoading = true);

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildExerciseModalSheet(),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildExerciseModalSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: FitnessAppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: _muscleGroups.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    indicatorColor: FitnessAppTheme.white,
                    indicatorWeight: 3,
                    labelColor: FitnessAppTheme.white,
                    unselectedLabelColor: Colors.grey[400],
                    tabs: _muscleGroups.map((muscle) {
                      return Tab(
                        child: Row(
                          children: [
                            Icon(muscle['icon'] as IconData),
                            const SizedBox(width: 8),
                            Text(muscle['name'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: _muscleGroups.map((muscle) =>
                        _buildExerciseList(muscle['name'] as String)
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(String muscle) {
    return FutureBuilder<List<Exercise>>(
      future: _fetchWorkoutExercises(muscle),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(FitnessAppTheme.white),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, color: Colors.grey, size: 48),
                SizedBox(height: 16),
                Text(
                  'No exercises found for this muscle group',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final exercise = snapshot.data![index];
            return _buildExerciseCard(exercise);
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () {
        // Create a new Exercise instance with empty sets
        final newExercise = Exercise(
          name: exercise.name,
          description: exercise.description,
          equipment: exercise.equipment,
          images: exercise.images,
          sets: [], // Initialize with empty sets
        );
        Provider.of<ExerciseModel>(context, listen: false).addExercise(newExercise);
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: exercise.images.isNotEmpty
                      ? Image.network(
                          exercise.images[0],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.fitness_center,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Exercise>> _fetchWorkoutExercises(String muscleType) async {
    const String baseUrl = APIConstants.baseUrl;
    final response =
        await http.get(Uri.parse('$baseUrl/exercise/?muscle_type=$muscleType'));

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
        backgroundColor: FitnessAppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _discardWorkout() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitnessAppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Discard Workout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to discard the current workout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (shouldDiscard ?? false) {
      final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);
      stopwatchProvider.resetStopwatch();
      stopwatchProvider.stopStopwatch();

      setState(() {
        _workoutStarted = false;
      });

      Provider.of<ExerciseModel>(context, listen: false).resetWorkout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('workoutStarted');
      await prefs.remove('elapsedMilliseconds');
      await prefs.remove('selectedExercises');

      Navigator.of(context).pop();
    }
  }

  Future<void> _performDiscardWorkout() async {
    final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);
    stopwatchProvider.resetStopwatch();
    stopwatchProvider.stopStopwatch();

    setState(() {
      _workoutStarted = false;
    });

    Provider.of<ExerciseModel>(context, listen: false).resetWorkout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('workoutStarted');
    await prefs.remove('elapsedMilliseconds');
    await prefs.remove('selectedExercises');

    // Optionally close the workout page
    Navigator.of(context).pop();
  }

  Future<void> _endWorkout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);
      final exerciseModel = Provider.of<ExerciseModel>(context, listen: false);

      final workoutData = {
        'duration': stopwatchProvider.elapsedMilliseconds,
        'exercises': exerciseModel.selectedExercises.map((exercise) {
          return {
            'name': exercise.name,
            'sets': exercise.sets.map((set) => set.toJson()).toList(),
          };
        }).toList(),
      };

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('authToken');

      const String baseUrl = APIConstants.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/logger/workout_receiver/'),
        headers: {"Content-Type": "application/json", 'Authorization': 'Token $authToken'},
        body: json.encode(workoutData),
      );

      if (response.statusCode == 201) {
        await _performDiscardWorkout(); // Directly discard without confirmation
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: FitnessAppTheme.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Workout Complete', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Your workout has been saved!',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((_) => Navigator.of(context).pop());
      } else {
        throw Exception('Failed to save workout: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error ending workout: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitnessAppTheme.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: FitnessAppTheme.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_workoutStarted)
              FloatingActionButton(
                onPressed: _discardWorkout,
                backgroundColor: Colors.red,
                child: const Icon(Icons.delete),
              ),
            if (_workoutStarted)
              FloatingActionButton.extended(
                onPressed: _showWorkoutExercises,
                backgroundColor: Color.fromARGB(255, 182, 176, 238),
                foregroundColor: FitnessAppTheme.background,
                icon: _isLoading
                    ? const SizedBox(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            if (_workoutStarted)
              FloatingActionButton.extended(
                onPressed: _endWorkout,
                backgroundColor: Colors.green,
                icon: const Icon(Icons.check),
                label: const Text('End'),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Consumer<StopwatchProvider>(
                    builder: (context, stopwatchProvider, child) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Workout Time: ${_formattedTime(stopwatchProvider.elapsedMilliseconds)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Consumer<ExerciseModel>(
                      builder: (context, model, child) {
                        return model.selectedExercises.isEmpty
                            ? Center(
                                child: Text(
                                  'No exercises selected',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: model.selectedExercises.length,
                                itemBuilder: (context, index) {
                                  final exercise = model.selectedExercises[index];
                                  return ExerciseTile(
                                    exercise: exercise,
                                    exerciseIndex: index,
                                    onSetsChanged: (exerciseIndex, updatedSets) {
                                      model.updateExerciseSets(
                                          exerciseIndex, updatedSets);
                                    },
                                  );
                                },
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
