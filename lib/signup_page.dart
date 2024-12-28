import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/health.dart';
import 'dart:convert';
import 'package:workout_logger/constants.dart';
import 'package:workout_logger/login_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({Key? key}) : super(key: key);

  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final List<HealthDataType> _healthTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
  ];

  final Health _health = Health();
  String? _loadingMessage;

  Future<bool> _requestHealthAuthorization() async {
    bool isAuthorized = false;
    if (_health.isDataTypeAvailable(HealthDataType.WORKOUT)) {
      isAuthorized = await _health.requestAuthorization(_healthTypes);
    } else {
      print("Health data types not available.");
    }
    return isAuthorized;
  }

  Future<List<HealthDataPoint>> _fetchHealthData() async {
    setState(() {
      _loadingMessage = "Syncing health data";
    });
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 7));
    List<HealthDataPoint> healthData = [];
    try {
      bool isAuthorized = await _requestHealthAuthorization();
      if (isAuthorized) {
        healthData = await _health.getHealthDataFromTypes(
          startTime: yesterday,
          endTime: now,
          types: _healthTypes,
        );
        healthData = _health.removeDuplicates(healthData);
      } else {
        print("Authorization not granted.");
      }
    } catch (error) {
      print("Error fetching health data: $error");
    } finally {
      setState(() {
        _loadingMessage = null;
      });
    }
    return healthData;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loadingMessage = "Logging in with Google";
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

          List<HealthDataPoint> healthData = await _fetchHealthData();

          final workoutData = healthData
              .where((data) => data.type == HealthDataType.WORKOUT)
              .map((data) => {
                    'value': data.value,
                    'start_date': data.dateFrom.toIso8601String(),
                    'end_date': data.dateTo.toIso8601String(),
                  })
              .toList();

          final heartRateData = healthData
              .where((data) => data.type == HealthDataType.HEART_RATE)
              .map((data) => {
                    'value': data.value,
                    'start_date': data.dateFrom.toIso8601String(),
                    'end_date': data.dateTo.toIso8601String(),
                  })
              .toList();

          await http.post(
            Uri.parse(APIConstants.syncWorkouts),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $authToken',
            },
            body: jsonEncode({
              'workout_data': workoutData,
              'heartrate_data': heartRateData,
            }),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
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

  Future<void> _signUpWithEmail() async {
    setState(() {
      _loadingMessage = "Creating profile";
    });

    try {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        setState(() {
          _loadingMessage = null;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(APIConstants.emailSignUp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final responseBody = jsonDecode(response.body);
      print("Server Response: $responseBody");

      if (response.statusCode == 201) {
        final String? authToken = responseBody['token'] as String?;
        if (authToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed: Invalid response')),
          );
          setState(() {
            _loadingMessage = null;
          });
          return;
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', authToken);

        List<HealthDataPoint> healthData = await _fetchHealthData();

        final workoutData = healthData
            .where((data) => data.type == HealthDataType.WORKOUT)
            .map((data) => {
                  'value': data.value,
                  'start_date': data.dateFrom.toIso8601String(),
                  'end_date': data.dateTo.toIso8601String(),
                })
            .toList();

        final heartRateData = healthData
            .where((data) => data.type == HealthDataType.HEART_RATE)
            .map((data) => {
                  'value': data.value,
                  'start_date': data.dateFrom.toIso8601String(),
                  'end_date': data.dateTo.toIso8601String(),
                })
            .toList();

        await http.post(
          Uri.parse(APIConstants.syncWorkouts),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $authToken',
          },
          body: jsonEncode({
            'workout_data': workoutData,
            'heartrate_data': heartRateData,
          }),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        final error = responseBody['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $error')),
        );
      }
    } catch (e) {
      print("Error during sign-up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
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
                      const SizedBox(height: 30),
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/fitquest_logo.png',
                            height: 100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle:
                              const TextStyle(color: Colors.white),
                          hintText: 'john123',
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
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle:
                              const TextStyle(color: Colors.white),
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
                          labelStyle:
                              const TextStyle(color: Colors.white),
                          hintText: '••••••••',
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
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle:
                              const TextStyle(color: Colors.white),
                          hintText: '••••••••',
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
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _signUpWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text(
                          'Create Profile',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(color: Colors.grey),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 8.0),
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
                        onPressed: _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
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
