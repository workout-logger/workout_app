// exercise_tile.dart
import 'package:flutter/material.dart';
import 'workout_set.dart';
import 'exercise.dart';
import '../fitness_app_theme.dart';

class ExerciseTile extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final Function(int, List<WorkoutSet>) onSetsChanged;

  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onSetsChanged,
  });

  @override
  _ExerciseTileState createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile> {
  late List<WorkoutSet> _sets;
  late List<TextEditingController> _repsControllers;
  late List<TextEditingController> _weightControllers;

  @override
  void initState() {
    super.initState();
    _sets = List<WorkoutSet>.from(widget.exercise.sets);
    _repsControllers = _sets
        .map((set) => TextEditingController(text: set.reps))
        .toList();
    _weightControllers = _sets
        .map((set) => TextEditingController(text: set.weight))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    setState(() {
      _sets.add(WorkoutSet(reps: '', weight: ''));
      _repsControllers.add(TextEditingController());
      _weightControllers.add(TextEditingController());
    });
    widget.onSetsChanged(widget.exerciseIndex, _sets);
  }

  void _removeSet(int index) {
    setState(() {
      if (_sets.length > 1) {
        _sets.removeAt(index);
        _repsControllers[index].dispose();
        _weightControllers[index].dispose();
        _repsControllers.removeAt(index);
        _weightControllers.removeAt(index);
      }
    });
    widget.onSetsChanged(widget.exerciseIndex, _sets);
  }

  void _updateSet(int index, String reps, String weight) {
    setState(() {
      _sets[index].reps = reps;
      _sets[index].weight = weight;
    });
    widget.onSetsChanged(widget.exerciseIndex, _sets);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[800], // Updated to a dark grey color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // Set mainAxisSize to min to allow the column to wrap its content
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Name and Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.exercise.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text
                  ),
                ),
                IconButton(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add, color: Colors.white), // White icon
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Sets List
            Flexible(
              fit: FlexFit.loose,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      // Reps TextField
                      Expanded(
                        child: TextField(
                          controller: _repsControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            labelStyle: TextStyle(color: Colors.white), // White label
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white), // White border
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white), // White border on focus
                            ),
                          ),
                          style: const TextStyle(color: Colors.white), // White input text
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateSet(index, value, _sets[index].weight);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Weight TextField
                      Expanded(
                        child: TextField(
                          controller: _weightControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Weight',
                            labelStyle: TextStyle(color: Colors.white), // White label
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white), // White border
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white), // White border on focus
                            ),
                          ),
                          style: const TextStyle(color: Colors.white), // White input text
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateSet(index, _sets[index].reps, value);
                          },
                        ),
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Color.fromARGB(255, 240, 142, 142)), // White icon
                        onPressed: () => _removeSet(index),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
