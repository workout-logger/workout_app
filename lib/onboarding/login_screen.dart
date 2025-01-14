import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:health/health.dart';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';
import 'package:workout_logger/onboarding/complete_profile_screen.dart';

import 'package:workout_logger/constants.dart';
import 'package:workout_logger/main.dart';
import 'package:workout_logger/onboarding/signup_page.dart';
import 'package:workout_logger/websocket_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // HealthKit / Health Connect setup
  final Health health = Health();
  final List<HealthDataType> types = [
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
  ];

  // For showing progress messages
  String? _loadingMessage;



  /// We add this to configure the health plugin on app startup.
  @override
  void initState() {
    super.initState();
    // Configure the Health plugin (important on both iOS and Android).
    health.configure();

    // If on Android, check the status of Health Connect.
    if (Platform.isAndroid) {
      health.getHealthConnectSdkStatus().then((status) {
        debugPrint('Health Connect SDK status: $status');
        // Optionally, if status != HealthConnectSdkStatus.sdkAvailable,
        // you might prompt the user to install Health Connect, etc.
      });
    }
  }

  /// Requests the needed permissions to read data from Apple Health or Health Connect.
  /// On Android, also asks for Activity Recognition and (optionally) Location.
  Future<bool> requestAuthorization() async {
    try {
      // If on Android, request the ACTIVITY_RECOGNITION permission (and location, if needed).
      if (Platform.isAndroid) {
        await Permission.activityRecognition.request();
        // If your workouts include distance (e.g., running/walking), you may also request location:
        await Permission.location.request();
      }

      // If you need more fine-grained READ vs. READ_WRITE logic, build out the permissions list:
      final permissions = types.map((_) => HealthDataAccess.READ).toList();

      // Check if we already have permissions
      bool? hasPermissions =
          await health.hasPermissions(types, permissions: permissions);

      // Because `hasPermissions` can be null, we check falsey:
      if (hasPermissions != true) {
        // Request authorization for the data types you need
        return await health.requestAuthorization(types, permissions: permissions);
      }
      // If we already had them
      return true;
    } catch (error) {
      debugPrint('Error requesting authorization: $error');
      return false;
    }
  }

  /// Fetches the user’s heart rate and workout data from the last ~3 years (999 days).
  /// Adjust the time range as you see fit.
  Future<List<HealthDataPoint>> fetchHealthData() async {
    setState(() {
      _loadingMessage = "Syncing data";
    });

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 999));
    List<HealthDataPoint> healthData = [];

    try {
      bool isAuthorized = await requestAuthorization();
      if (!isAuthorized) {
        debugPrint('Authorization not granted');
        return [];
      }

      // We have permission—go ahead and fetch data
      healthData = await health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: now,
        types: types,
      );

      // Remove duplicates, just in case
      healthData = health.removeDuplicates(healthData);

    } catch (error, stack) {
      debugPrint("Error fetching health data: $error");
      debugPrint("Stack trace: $stack");
    } finally {
      setState(() {
        _loadingMessage = null;
      });
    }
    return healthData;
  }


  Future<void> _handleGuestSignIn(BuildContext context) async {
    setState(() => _loadingMessage = "Creating guest account...");
    try {
      // Send a request to the guest signup endpoint
      final response = await http.post(
        Uri.parse(APIConstants.guestSignIn),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);

        // Example: Save auth token and other details locally
        final String authToken = responseBody['token'];
        final bool isNewUser = responseBody['is_new_user'] ?? true;
        // Save token in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', authToken);

        // If the guest is considered a new user, navigate to the profile screen
        if (isNewUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UsernameScreen()),
          );
        } else {
          // Navigate to the home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        // Handle guest signup failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest signup failed: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() => _loadingMessage = null);
    }
  }


  /// Google Sign In logic
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _loadingMessage = "Logging in");
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the Google Sign-In
        setState(() => _loadingMessage = null);
        return;
      }

      // Retrieve auth details
      final googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      // Send token to your server
      final response = await http.post(
        Uri.parse(APIConstants.googleSignIn),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // For example:
        final String authToken = responseBody['key'];
        final bool isNewUser = responseBody['is_new_user'] ?? false;

        // Save token in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', authToken);

        // If new user or profile not done, show the profile creation
        if (isNewUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UsernameScreen()),
          );
        } else {
          // Show a loading indicator while connecting
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            await WebSocketManager().connectWebSocket();
            Navigator.pop(context); // Remove the loading indicator

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } catch (e) {
            Navigator.pop(context); // Remove the loading indicator
            // Show an error message to the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to connect: $e')),
            );
          }
        }

      } else {
        // Sign in failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $error')),
      );
    } finally {
      setState(() => _loadingMessage = null);
    }
  }


 

  /// Builds the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _loadingMessage != null
            ? Center(
                child: Text(
                  _loadingMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 100),
                          Image.asset(
                            'assets/images/fitquest_logo.png',
                            height: 100,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      const SizedBox(height: 60),
                      
                      OutlinedButton(
                        onPressed: () async {
                          await _handleGuestSignIn(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.yellow),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text(
                          'Continue as guest',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(color: Colors.grey),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _handleGoogleSignIn(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/images/google_white_logo.png',
                          height: 24,
                        ),
                        label: const Text(
                          'Google',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

