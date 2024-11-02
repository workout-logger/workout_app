import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_model.dart';
import 'stopwatch_provider.dart';
import 'package:workout_logger/exercise.dart';
import 'fitness_app_theme.dart';
import 'package:http/http.dart' as http;


class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseTile({required this.exercise});

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
              exercise.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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

    final exercisesJson = json.encode(exerciseModel.selectedExercises.map((e) => e.toJson()).toList());
    prefs.setString('selectedExercises', exercisesJson);
  }

  Future<void> _loadWorkoutState() async {
    final prefs = await SharedPreferences.getInstance();
    _workoutStarted = prefs.getBool('workoutStarted') ?? false;

    final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);
    final savedElapsedMilliseconds = prefs.getInt('elapsedMilliseconds') ?? 0;

    if (_workoutStarted) {
      stopwatchProvider.startStopwatch(initialMilliseconds: savedElapsedMilliseconds);
    }

    final exercisesJson = prefs.getString('selectedExercises');
    if (exercisesJson != null) {
      final exercisesList = (json.decode(exercisesJson) as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
      Provider.of<ExerciseModel>(context, listen: false).setExercises(exercisesList);
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
        Provider.of<ExerciseModel>(context, listen: false).addExercise(exercise);
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
                          fit: BoxFit.cover,
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
    const String baseUrl = 'https://jaybird-exciting-merely.ngrok-free.app';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitnessAppTheme.background,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_workoutStarted)
            FloatingActionButton.extended(
              onPressed: _discardWorkout,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete),
              label: const Text('Discard Workout'),
            ),
          const SizedBox(height: 10),
          if (_workoutStarted)
            FloatingActionButton.extended(
              onPressed: _showWorkoutExercises,
              backgroundColor: FitnessAppTheme.white,
              foregroundColor: FitnessAppTheme.background,
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_workoutStarted
                  ? Center(
                      child: GestureDetector(
                        onTap: _startWorkout,
                        child: const SizedBox(
                          width: 200,
                          height: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 48,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Start Workout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Column(
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
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: model.selectedExercises.length,
                                      itemBuilder: (context, index) {
                                        final exercise = model.selectedExercises[index];
                                        return _ExerciseTile(exercise: exercise);
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

  Future<void> _discardWorkout() async {
    final stopwatchProvider = Provider.of<StopwatchProvider>(context, listen: false);
    stopwatchProvider.stopStopwatch();
    
    setState(() {
      _workoutStarted = false;
    });

    Provider.of<ExerciseModel>(context, listen: false).setExercises([]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('workoutStarted');
    await prefs.remove('elapsedMilliseconds');
    await prefs.remove('selectedExercises');
  }
}
