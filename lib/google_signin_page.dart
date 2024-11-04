import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:workout_logger/main.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:health/health.dart';
import 'dart:io' show Platform;

class GoogleSignInPage extends StatefulWidget {
  GoogleSignInPage({super.key});

  @override
  _GoogleSignInPageState createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  String? _loadingMessage; // Updated to hold a string message

  final types = [
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
  ];

  final Health health = Health();

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _loadingMessage = "Logging in"; // Set loading message for login
    });
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final String? accessToken = googleAuth.accessToken;

        final response = await http.post(
          Uri.parse(
              'https://jaybird-exciting-merely.ngrok-free.app/api/social/google/'),
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
        _loadingMessage = null; // Reset loading message
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
      _loadingMessage = "Syncing data"; // Set loading message for syncing data
    });
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 999));

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
    } catch (error) {
      print("Error fetching health data: $error");
    } finally {
      setState(() {
        _loadingMessage = null; // Reset loading message after syncing
      });
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
      backgroundColor: Colors.black,
      body: _loadingMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    _loadingMessage!,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Spacer(flex: 3),
                Center(
                  child: Container(
                    height: 30,
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
                        // Other language text options here...
                      ],
                      repeatForever: true,
                    ),
                  ),
                ),
                Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _handleGoogleSignIn(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
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
                    SizedBox(width: 40),
                    GestureDetector(
                      onTap: () {
                        // Add Facebook login handling here
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
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
                Spacer(),
              ],
            ),
    );
  }
}
