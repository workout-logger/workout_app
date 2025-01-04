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

  // Text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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

  /// Completes the sign-in process by fetching health data and syncing to your server.
  Future<void> _completeSignIn(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setBool('firstLaunch', false);

      // 1. Fetch health data
      List<HealthDataPoint> healthData = await fetchHealthData();
      
      // 2. Prepare data for your backend
      final String? authToken = prefs.getString('authToken');

      final workoutData = healthData
          .where((dp) => dp.type == HealthDataType.WORKOUT)
          .map((dp) => {
                'value': dp.value,
                'start_date': dp.dateFrom.toIso8601String(),
                'end_date': dp.dateTo.toIso8601String(),
              })
          .toList();

      final heartRateData = healthData
          .where((dp) => dp.type == HealthDataType.HEART_RATE)
          .map((dp) => {
                'value': dp.value,
                'start_date': dp.dateFrom.toIso8601String(),
                'end_date': dp.dateTo.toIso8601String(),
              })
          .toList();

      final dataToSend = {
        'authToken': authToken,
        'workout_data': workoutData,
        'heartrate_data': heartRateData,
      };

      // 3. POST data to your server
      await http.post(
        Uri.parse(APIConstants.syncWorkouts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode(dataToSend),
      );

      // 4. Go to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (error) {
      debugPrint("Error during completion: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete sign-in: $error')),
      );
      setState(() {
        _loadingMessage = null;
      });
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
        print(authToken);
        await prefs.setString('authToken', authToken);

        // If new user or profile not done, show the profile creation
        if (isNewUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UsernameScreen()),
          );
        } else {
          await WebSocketManager().connectWebSocket();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
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


  /// Sign in with email
  Future<void> _signInWithEmail() async {
    setState(() {
      _loadingMessage = "Signing in";
    });

    try {
      final response = await http.post(
        Uri.parse(APIConstants.emailSignIn),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final responseBody = jsonDecode(response.body);
      debugPrint("Server Response: $responseBody");

      if (response.statusCode == 200) {
        final String? authToken = responseBody['token'] as String?;
        if (authToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed: Invalid response')),
          );
          setState(() {
            _loadingMessage = null;
          });
          return;
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', authToken);
        await _completeSignIn(context);
      } else {
        final error = responseBody['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $error')),
        );
        setState(() {
          _loadingMessage = null;
        });
      }

    } catch (e) {
      debugPrint("Error during sign-in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
      setState(() {
        _loadingMessage = null;
      });
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
                          const SizedBox(height: 30),
                          Image.asset(
                            'assets/images/fitquest_logo.png',
                            height: 100,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email or Username',
                          labelStyle: const TextStyle(color: Colors.white),
                          hintText: 'email@gmail.com',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          suffixText: 'Forgot?',
                          suffixStyle: const TextStyle(color: Colors.yellow),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () {
                          // If you want to allow users as "guests," handle that logic here.
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
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SignUpScreen()),
                              );
                            },
                            child: const Text(
                              'Create now',
                              style: TextStyle(color: Colors.yellow),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

