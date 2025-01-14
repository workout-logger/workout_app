import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:health/health.dart';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/onboarding/complete_profile_screen.dart';
import 'package:workout_logger/constants.dart';
import 'package:workout_logger/main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Configure the Health plugin
    health.configure();

    if (Platform.isAndroid) {
      health.getHealthConnectSdkStatus().then((status) {
        debugPrint('Health Connect SDK status: $status');
      });
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      if (Platform.isAndroid) {
        await Permission.activityRecognition.request();
        await Permission.location.request();
      }

      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      bool? hasPermissions =
          await health.hasPermissions(types, permissions: permissions);

      if (hasPermissions != true) {
        return await health.requestAuthorization(types, permissions: permissions);
      }
      return true;
    } catch (error) {
      debugPrint('Error requesting authorization: $error');
      return false;
    }
  }

  Future<void> _handleGoogleSignUp(BuildContext context) async {
    setState(() => _loadingMessage = "Signing up");
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loadingMessage = null);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      final response = await http.post(
        Uri.parse(APIConstants.emailSignUp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String authToken = responseBody['key'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', authToken);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UsernameScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $error')),
      );
    } finally {
      setState(() => _loadingMessage = null);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _loadingMessage = "Signing up";
    });

    try {
      final response = await http.post(
        Uri.parse(APIConstants.emailSignUp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final String authToken = jsonDecode(response.body)['token'];
        await prefs.setString('authToken', authToken);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UsernameScreen()),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $error')),
        );
      }
    } catch (e) {
      debugPrint("Error during sign-up: $e");
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
      body: SafeArea(
        child: _loadingMessage != null
            ? Center(
                child: Text(
                  _loadingMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    Image.asset('assets/images/fitquest_logo.png', height: 100),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white),
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
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(color: Colors.white),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _handleGoogleSignUp(context);
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
                  ],
                ),
              ),
      ),
    );
  }
}
