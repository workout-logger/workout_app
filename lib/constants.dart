class APIConstants {
  static const String baseUrl = 'https://jaybird-exciting-merely.ngrok-free.app';

  // Endpoints
  static const String googleSignIn = '$baseUrl/api/social/google/';
  static const String syncWorkouts = '$baseUrl/logger/sync_workouts/';
  static const String lastWorkout = '$baseUrl/logger/last_workout/';
  static const String updateLatestMuscleGroups = '$baseUrl/logger/workout/update_latest_muscle_groups/';
}