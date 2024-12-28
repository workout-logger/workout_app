import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:health/health.dart';
import 'dart:convert';
import 'package:workout_logger/constants.dart';
import 'package:workout_logger/main.dart';
import 'package:workout_logger/signup_page.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  String? _loadingMessage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final types = [
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
  ];
  
  final Health health = Health();

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _loadingMessage = "Logging in";
    });
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final String? accessToken = googleAuth.accessToken;

        final response = await http.post(
          Uri.parse(APIConstants.googleSignIn),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'access_token': accessToken}),
        );
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final String authToken = responseBody['key'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', authToken);
          await _completeSignIn(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${response.body}')),
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $error')),
      );
    } finally {
      setState(() {
        _loadingMessage = null;
      });
    }
  }

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
      print("Server Response: $responseBody");

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
          _loadingMessage = null; // Reset on error
        });
      }

    } catch (e) {
      print("Error during sign-in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
      setState(() {
        _loadingMessage = null;
      });
    }
  }

  Future<bool> requestAuthorization() async {
    bool isAuthorized = false;
    if (Platform.isAndroid || Platform.isIOS) {
      isAuthorized = await health.requestAuthorization(types);
      print('Health APIs are available on this platform.');
    } else {
      print('Health APIs are not available on this platform.');
    }
    return isAuthorized;
  }

  Future<List<HealthDataPoint>> fetchHealthData() async {
    setState(() {
      _loadingMessage = "Syncing data";
    });
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 999));

    List<HealthDataPoint> healthData = [];

    try {
      bool isAuthorized = await requestAuthorization();

      if (isAuthorized) {
        healthData = await health.getHealthDataFromTypes(
          startTime: yesterday,
          endTime: now,
          types: types,
        );
        healthData = health.removeDuplicates(healthData);
      } else {
        print('Authorization not granted');
        print('Error: Health data access not authorized by user');
      }
    }  catch (error) {
      print("Error fetching health data: $error");
      print("Error details: ${error.toString()}");
      print("Error stack trace: ${StackTrace.current}");
      setState(() {
        _loadingMessage = null; // Reset on error
      });
    }
    return healthData;
  }

  Future<void> _completeSignIn(BuildContext context) async {
    try {
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

      await http.post(
        Uri.parse(APIConstants.syncWorkouts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode(dataToSend),
      );

      // Navigate to the home screen and reset the loading message after navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } catch (error) {
      print("Error during completion: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete sign-in: $error')),
      );
      setState(() {
        _loadingMessage = null;
      });
    }
  }

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
                        onPressed: () {},
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
                                        const CreateProfileScreen()),
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
