import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:workout_logger/constants.dart';
import 'dart:convert';
import 'package:workout_logger/main.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:health/health.dart';
import 'package:workout_logger/lottie_segment_player.dart';
import 'dart:io' show Platform;

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  _GoogleSignInPageState createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
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

  Future<void> _signUpWithEmail() async {
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
        await _completeSignIn(context);
      } else {
        final error = responseBody['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $error')),
        );
        setState(() {
          _loadingMessage = null; // Reset on error
        });
      }

    } catch (e) {
      print("Error during sign-up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
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
      }
    }  catch (error) {
      print("Error fetching health data: $error");
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
      body: _loadingMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LottieSegmentPlayer(
                    animationPath: 'assets/animations/loading.json', // Update with your path
                    width: 100,
                    height: 100,
                    endFraction: 0.7
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _loadingMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: SizedBox(
                        height: 30,
                        child: AnimatedTextKit(
                          animatedTexts: [
                            FadeAnimatedText(
                              'Sign in or Register',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                                fontFamily: 'Roboto',
                              ),
                              duration: const Duration(milliseconds: 2000),
                            ),
                          ],
                          repeatForever: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Email Input
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password Input
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Sign-Up and Sign-In Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _signUpWithEmail,
                          child: const Text('Sign Up'),
                        ),
                        ElevatedButton(
                          onPressed: _signInWithEmail,
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'OR',
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Divider(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Social Sign-In Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Sign-In
                        GestureDetector(
                          onTap: () async {
                            await _handleGoogleSignIn(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                              'assets/images/google_white_logo.png',
                              height: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Facebook Sign-In
                        GestureDetector(
                          onTap: () {
                            // Add Facebook login handling here
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                              'assets/images/facebook_white_logo.png',
                              height: 48,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
