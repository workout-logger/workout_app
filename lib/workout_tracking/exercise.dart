// exercise.dart
import 'package:uuid/uuid.dart';
import 'workout_set.dart';

class Exercise {
  final String id;
  final String name;
  final String description;
  final String? equipment;
  final List<String> images;
  List<WorkoutSet> sets;

  static final Uuid _uuid = Uuid();

  Exercise({
    String? id,
    required this.name,
    required this.description,
    this.equipment,
    required this.images,
    this.sets = const [],
  }) : id = id ?? _uuid.v4();

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Debugging: Print incoming JSON
    print('Deserializing Exercise: $json');

    return Exercise(
      id: json['id'] as String? ?? _uuid.v4(),
      name: json['name'] as String? ?? 'Unnamed Exercise',
      description: _removeHtmlTags(json['description'] as String? ?? ''),
      equipment: json['equipment'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List<dynamic>)
          : [],
      sets: json['sets'] != null
          ? (json['sets'] as List<dynamic>)
              .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'equipment': equipment,
      'images': images,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  static String _removeHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }
}
