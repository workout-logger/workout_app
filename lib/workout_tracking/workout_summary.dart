// workout_summary_page.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Add lottie package
import 'package:provider/provider.dart';
import 'package:workout_logger/refresh_notifier.dart';
import '../fitness_app_theme.dart';

class WorkoutSummaryPage extends StatelessWidget {
  final int strengthGained;
  final int agilityGained;
  final int speedGained;

  const WorkoutSummaryPage({
    Key? key,
    required this.strengthGained,
    required this.agilityGained,
    required this.speedGained,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitnessAppTheme.background,
      appBar: AppBar(
        backgroundColor: FitnessAppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/animations/congrats.json', // Ensure this file exists in assets
                width: 300,
                height: 300,
                repeat: true,
              ),
              const SizedBox(height: 20),
              Text(
                'Congratulations!',
                style: TextStyle(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildMetricCard('Strength Increased', strengthGained, Icons.fitness_center, Colors.redAccent),
              _buildMetricCard('Agility Increased', agilityGained, Icons.directions_walk, Colors.greenAccent),
              _buildMetricCard('Speed Increased', speedGained, Icons.flash_on, Colors.blueAccent),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Provider.of<RefreshNotifier>(context, listen: false).requestRefresh();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Back Home',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, int value, IconData icon, Color color) {
    return Card(
      color: FitnessAppTheme.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(
          title,
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 255, 255),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          "+$value",
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 255, 255),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
