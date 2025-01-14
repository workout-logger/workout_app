import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:workout_logger/constants.dart';

class PastWorkoutsScreen extends StatefulWidget {
  @override
  _PastWorkoutsScreenState createState() => _PastWorkoutsScreenState();
}

class _PastWorkoutsScreenState extends State<PastWorkoutsScreen> {
  List<dynamic> _workouts = [];
  bool _isLoading = true;
  String? _error;

  // Replace with your actual API endpoint
  final String apiUrl = APIConstants.allWorkouts;

  // Get auth token from SharedPreferences
  late String authToken;


  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      authToken = prefs.getString('authToken') ?? '';
      fetchPastWorkouts();
    });
  }

  Future<void> fetchPastWorkouts() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _workouts = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load workouts: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Past Workouts', 
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold
        )
      ),
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    body: Container(
      color: Colors.black,
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Text(_error!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16
                    )
                  )
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: _workouts.length,
                  itemBuilder: (context, index) {
                    final workout = _workouts[index];
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)
                      ),
                      color: Color(0xFF1E1E1E),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Workout on ${DateTime.parse(workout['workout_date']).toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard('Duration', formatDuration(workout['duration'])),
                                _buildStatCard('Energy', '${workout['energy_burned']} kcal'),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard('Strength', '+${workout['strength_gained']}'),
                                _buildStatCard('Agility', '+${workout['agility_gained']}'),
                                _buildStatCard('Speed', '+${workout['speed_gained']}'),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Exercises:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500
                                    )
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    workout['exercises_done'].map((e) => e['name']).join(', '),
                                    style: TextStyle(color: Colors.grey[400])
                                  ),
                                  SizedBox(height: 8),
                                  Text('Muscle Groups:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500
                                    )
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    workout['muscle_groups'].map((m) => m['name']).join(', '),
                                    style: TextStyle(color: Colors.grey[400])
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    ),
  );
}

Widget _buildStatCard(String label, String value) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(10)
    ),
    child: Column(
      children: [
        Text(label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14
          )
        ),
        SizedBox(height: 4),
        Text(value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold
          )
        ),
      ],
    ),
  );
}}

