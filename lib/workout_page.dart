import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';
import 'exercise_model.dart';
import 'package:workout_logger/exercise.dart';
import 'fitness_app_theme.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _workoutStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      _resumeTimer();
    }
  }

  void _startWorkout() {
    setState(() {
      _workoutStarted = true;
      _stopwatch.start();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  void _pauseTimer() {
    _timer?.cancel();
    _stopwatch.stop();
  }

  void _resumeTimer() {
    if (_workoutStarted && !_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  String _formattedTime() {
    final elapsed = _stopwatch.elapsed;
    return '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
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
    final String baseUrl = Platform.isAndroid
        ? 'https://jaybird-exciting-merely.ngrok-free.app'
        : 'http://localhost:8000';
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
      floatingActionButton: _workoutStarted
          ? FloatingActionButton.extended(
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
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_workoutStarted
                  ? Center(
                      child: GestureDetector(
                        onTap: _startWorkout,
                        child: Container(
                          width: 200,
                          height: 200,
                          child: const Column(
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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Workout Time: ${_formattedTime()}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Consumer<ExerciseModel>(
                              builder: (context, model, child) {
                                return model.selectedExercises.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No exercises selected',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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

}

class _WorkoutExercisesList extends StatelessWidget {
  final List<Exercise> exercises;
  final Function(Exercise) onExerciseSelected;

  const _WorkoutExercisesList({super.key, required this.exercises, required this.onExerciseSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return GestureDetector(
          onTap: () => onExerciseSelected(exercise),
          child: _buildExerciseCard(context, exercise),
        );
      },
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF030303), Color(0xFF242424)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 2,
            spreadRadius: 0.1,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    exercise.images.isNotEmpty ? exercise.images[0] : '',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatefulWidget {
  final Exercise exercise;

  const _ExerciseTile({super.key, required this.exercise});

  @override
  __ExerciseTileState createState() => __ExerciseTileState();
}

class __ExerciseTileState extends State<_ExerciseTile> {
  late List<Map<String, String>> sets;
  late List<TextEditingController> repsControllers;
  late List<TextEditingController> weightControllers;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<ExerciseModel>(context, listen: false);
    sets = model.getSets(widget.exercise.name);

    repsControllers = sets.map((set) => TextEditingController(text: set['reps'])).toList();
    weightControllers = sets.map((set) => TextEditingController(text: set['weight'])).toList();

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
    for (var controller in [...repsControllers, ...weightControllers]) {
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
            ...sets.asMap().entries.map((entry) {
              final index = entry.key;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: repsControllers[index],
                        labelText: 'Reps',
                        onChanged: (value) => _updateSet(index, 'reps', value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: weightControllers[index],
                        labelText: 'Weight',
                        onChanged: (value) => _updateSet(index, 'weight', value),
                      ),
                    ),
                  ],
                ),
              );
            }),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required Function(String) onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        hintText: 'Enter $labelText',
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
      controller: controller,
      onChanged: onChanged,
    );
  }

  void _updateSet(int index, String field, String value) {
    sets[index][field] = value;
    Provider.of<ExerciseModel>(context, listen: false).updateSets(widget.exercise.name, sets);
  }
}
