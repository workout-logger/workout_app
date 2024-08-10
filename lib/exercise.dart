// lib/exercise.dart
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
