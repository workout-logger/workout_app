import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:workout_logger/main.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:health/health.dart';
import 'dart:io' show Platform;


class GoogleSignInPage extends StatelessWidget {
  GoogleSignInPage({super.key});

  // Initialize GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  bool _isLoading = false;
  final types = [
    // HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT
    // HealthDataType.RESTING_HEART_RATE,
  ];

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // Attempt to sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // Retrieve the authentication object
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Extract the access token
        final String? accessToken = googleAuth.accessToken;

        // Send the access token to your Django backend
        final response = await http.post(
          Uri.parse(
              'https://jaybird-exciting-merely.ngrok-free.app/api/social/google/'), // Replace with your Django backend URL
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'access_token': accessToken}),
        );
        if (response.statusCode == 200) {
          // Successful login
          final responseBody = jsonDecode(response.body);
          final String authToken = responseBody['key'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', authToken);
          await _completeSignIn(context);
        } else {
          // Handle login error (e.g., show a snackbar)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${response.body}')),
          );
        }
      }
    } catch (error) {
      print("Error during Google sign-in: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $error')),
      );
    }
  }


  final Health health = Health(); // Create a singleton instance of Health

  Future<bool> requestAuthorization() async {
    bool isAuthorized = false;
    if (Platform.isAndroid || Platform.isIOS) {
      isAuthorized = await health.requestAuthorization(types);
    } else {
      print('Health APIs are not available on this platform.');
    }
    return isAuthorized;
  }

  Future<List<HealthDataPoint>> fetchHealthData() async {
    final Health health = Health();
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 999));

    List<HealthDataPoint> healthData = [];

    try {
      bool isAuthorized = await requestAuthorization();

      if (isAuthorized) {
        healthData = await health.getHealthDataFromTypes(
          startTime: yesterday,
          endTime: now,
          types: types, // Only one `types` parameter as a named argument
        );
        healthData = health.removeDuplicates(healthData);
      } else {
        print('Authorization not granted');
      }
    } catch (error) {
      print("Error fetching health data: $error");
    }
    return healthData;
  }




  Future<void> _completeSignIn(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLaunch', false); 

    List<HealthDataPoint> healthData = await fetchHealthData();
    final String? authToken = prefs.getString('authToken');

    final workoutData = healthData
        .where((dataPoint) => dataPoint.type == HealthDataType.WORKOUT)
        .map((dataPoint) => {
              'value': dataPoint.value,
              'start_date': dataPoint.dateFrom.toIso8601String(),
              'end_date': dataPoint.dateTo.toIso8601String(),
            })
        .toList();

    final heartRateData = healthData
        .where((dataPoint) => dataPoint.type == HealthDataType.HEART_RATE)
        .map((dataPoint) => {
              'value': dataPoint.value,
              'start_date': dataPoint.dateFrom.toIso8601String(),
              'end_date': dataPoint.dateTo.toIso8601String(),
            })
        .toList();

    final dataToSend = {
      'authToken': authToken,
      'workout_data': workoutData,
      'heartrate_data': heartRateData,
    };

    // Send data to backend
    await http.post(
      Uri.parse('https://jaybird-exciting-merely.ngrok-free.app/logger/sync_workouts/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $authToken',
      },
      body: jsonEncode(dataToSend),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background to black
      body: Column(
        children: [
          Spacer(flex: 3), // Pushes text to the middle of the screen
          Center(
            child: Container(
              height: 30, // Fixed height to prevent shifting
              child: AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'Sign in or Register',
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                      fontFamily: 'Roboto',
                    ),
                    duration: Duration(milliseconds: 2000),
                  ),
                  FadeAnimatedText(
                    'S’inscrire ou se connecter', // French
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                      fontFamily: 'Roboto',
                    ),
                    duration: Duration(milliseconds: 2000),
                  ),
                  FadeAnimatedText(
                    'Registrarse o Iniciar sesión', // Spanish
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                      fontFamily: 'Roboto',
                    ),
                    duration: Duration(milliseconds: 2000),
                  ),
                  FadeAnimatedText(
                    'Anmelden oder Registrieren', // German
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                      fontFamily: 'Roboto',
                    ),
                    duration: Duration(milliseconds: 2000),
                  ),
                  FadeAnimatedText(
                    'Registrati o Accedi', // Italian
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                      fontFamily: 'Roboto',
                    ),
                    duration: Duration(milliseconds: 2000),
                  ),
                  FadeAnimatedText(
                    'サインインまたは登録', // Japanese
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                      fontFamily: 'Roboto',
                    ),
                    duration: Duration(milliseconds: 2000),
                  ),
                ],
                repeatForever: true,
              ),
            ),
          ),
          Spacer(flex: 2), // Pushes logos lower on the screen
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  await _handleGoogleSignIn(context);
                },
                child: Container(
                  padding: EdgeInsets.all(8), // Minimal padding for glow
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.10),
                        spreadRadius: 5,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/google_white_logo.png', // Google logo
                    height: 48,
                  ),
                ),
              ),
              SizedBox(width: 40), // Space between logos
              GestureDetector(
                onTap: () {
                  // Add handling for Facebook login here
                },
                child: Container(
                  padding: EdgeInsets.all(8), // Minimal padding for glow
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.10),
                        spreadRadius: 5,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/facebook_white_logo.png', // Facebook logo
                    height: 48,
                  ),
                ),
              ),
              SizedBox(width: 40), // Space between logos
              GestureDetector(
                onTap: () {
                  // Add handling for Twitter login here
                },
                child: Container(
                  padding: EdgeInsets.all(8), // Minimal padding for glow
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.10),
                        spreadRadius: 5,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/twitter_white_logo.png', // Twitter logo
                    height: 48,
                  ),
                ),
              ),
            ],
          ),
          Spacer(), // Pushes content further down
        ],
      ),
    );
  }
}
