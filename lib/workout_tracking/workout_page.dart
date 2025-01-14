// workout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/home_diary.dart';
import 'package:workout_logger/workout_tracking/workout_summary.dart';
import 'exercise_tile.dart';
import 'exercise_model.dart';
import 'stopwatch_provider.dart';
import 'exercise.dart';
import '../fitness_app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:workout_logger/constants.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

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
    {'name': 'Legs', 'color': const Color(0xFFD4A5A5), 'icon': Icons.fitness_center},
    {'name': 'Core', 'color': const Color(0xFF9B786F), 'icon': Icons.fitness_center},
    {'name': 'Back', 'color': const Color(0xFF9B786F), 'icon': Icons.fitness_center},
    {'name': 'Lower Back', 'color': const Color(0xFFA8E6CE), 'icon': Icons.fitness_center},
    {'name': 'Forearms', 'color': const Color(0xFFFF8C94), 'icon': Icons.fitness_center},
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
                        ExerciseList(
                          muscleType: muscle['name'] as String,
                          fetchExercises: _fetchWorkoutExercises, // Pass the fetch function
                        )
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

  // Updated to accept muscleType and page, and pass to ExerciseList
  Future<List<Exercise>> _fetchWorkoutExercises(String muscleType, int page) async {
    const String baseUrl = APIConstants.baseUrl;
    const int pageSize = 10; // Adjust the page size as needed

    final response = await http.get(
      Uri.parse('$baseUrl/exercise/?muscle_type=$muscleType&page=$page&page_size=$pageSize'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      

      final List<dynamic> data = responseBody['exercises'];

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

    // Do not pop the page here
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
        final responseBody = json.decode(response.body);
        final message = responseBody['message'];
        final totalCalories = (responseBody['total_calories'] as num).toInt();
        final strengthGained = (responseBody['strength_gained'] as num).toInt();
        final agilityGained = (responseBody['agility_gained'] as num).toInt();
        final speedGained = (responseBody['speed_gained'] as num).toInt();

        await _performDiscardWorkout(); // Reset the state without popping

        // Navigate to WorkoutSummaryPage and await the result
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryPage(
              strengthGained: strengthGained,
              agilityGained: agilityGained,
              speedGained: speedGained,
            ),
          ),
        );

        // Pop the modal bottom sheet with the result
        Navigator.of(context).pop(result); // Pass the result back to MyDiaryScreen
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

  Future<void> _deleteExercise(int exerciseIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitnessAppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Delete Exercise',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this exercise?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      setState(() {
        exerciseModel.deleteExercise(exerciseIndex);
      });

      // Optionally, show a snackbar or confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercise deleted'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitnessAppTheme.background,
      resizeToAvoidBottomInset: true, // Allow resizing when keyboard is shown
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingActionButtons(),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Dismiss the keyboard
          child: Column(
            children: [
              _buildStopwatchDisplay(),
              Expanded(
                child: Consumer<ExerciseModel>(
                  builder: (context, model, child) {
                    return model.selectedExercises.isEmpty
                        ? _buildNoExercisesMessage()
                        : ListView.builder(
                            itemCount: model.selectedExercises.length,
                            padding: const EdgeInsets.only(bottom: 100), // Extra padding for floating action buttons
                            itemBuilder: (context, index) {
                              final exercise = model.selectedExercises[index];
                              return ExerciseTile(
                                exercise: exercise,
                                exerciseIndex: index,
                                onSetsChanged: (exerciseIndex, updatedSets) {
                                  model.updateExerciseSets(exerciseIndex, updatedSets);
                                },
                                onExerciseDeleted: _deleteExercise, // Handle exercise deletion
                              );
                            },
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Container(
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
              backgroundColor: const Color.fromARGB(255, 182, 176, 238),
              foregroundColor: FitnessAppTheme.background,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
    );
  }

  Widget _buildStopwatchDisplay() {
    return Consumer<StopwatchProvider>(
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
    );
  }

  Widget _buildNoExercisesMessage() {
    return Center(
      child: Text(
        'No exercises selected',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// A separate widget to handle the exercise list with infinite scrolling
class ExerciseList extends StatefulWidget {
  final String muscleType;
  final Future<List<Exercise>> Function(String muscleType, int page) fetchExercises;

  const ExerciseList({
    Key? key,
    required this.muscleType,
    required this.fetchExercises,
  }) : super(key: key);

  @override
  _ExerciseListState createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList> {
  static const _pageSize = 10;

  final PagingController<int, Exercise> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await widget.fetchExercises(widget.muscleType, pageKey);

      if (!mounted) return; // Check if widget is still mounted

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      if (!mounted) return; // Check if widget is still mounted
      _pagingController.error = error;
    }
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

  @override
  Widget build(BuildContext context) {
    return PagedGridView<int, Exercise>(
      pagingController: _pagingController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      builderDelegate: PagedChildBuilderDelegate<Exercise>(
        itemBuilder: (context, exercise, index) => _buildExerciseCard(exercise),
        firstPageErrorIndicatorBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: ${_pagingController.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _pagingController.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        noItemsFoundIndicatorBuilder: (context) => const Center(
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
        ),
        newPageErrorIndicatorBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: ${_pagingController.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _pagingController.retryLastFailedRequest(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
