class APIConstants {
  static const String baseUrl = 'https://jaybird-exciting-merely.ngrok-free.app';
  //https://jaybird-exciting-merely.ngrok-free.app
  //http://18.219.196.93

  static const String socketUrl = 'wss://jaybird-exciting-merely.ngrok-free.app';
  // Endpoints
  static const String userExists = '$baseUrl/api/social/username_exists/?username=';
  static const String saveUserPreferences = '$baseUrl/api/social/save_user_preferences/';
  static const String googleSignIn = '$baseUrl/api/social/google/';
  static const String guestSignIn = '$baseUrl/api/social/guest/';
  static const String emailSignUp = '$baseUrl/api/social/register/';
  static const String emailSignIn = '$baseUrl/api/social/login/';
  static const String allWorkouts = '$baseUrl/logger/past_workouts/';
  static const String syncWorkouts = '$baseUrl/logger/sync_workouts/';
  static const String lastWorkout = '$baseUrl/logger/last_workout/';
  static const String updateLatestMuscleGroups = '$baseUrl/logger/workout/update_latest_muscle_groups/';
  static const String equippedItems = '$baseUrl/api/inventory/get_equipped_items/';
  static const String buyChest = '$baseUrl/api/inventory/buy_chest/';
  static const String sellMarket = '$baseUrl/api/inventory/marketplace/add_listing/';
  static const String buyMarket = '$baseUrl/api/inventory/marketplace/buy/';
  static const String showListings = '$baseUrl/api/inventory/marketplace/';
}
