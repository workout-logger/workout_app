import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// Remove unused theme import if FitnessAppTheme specific colors/fonts aren't needed
// import '../fitness_app_theme.dart'; 

class WorkoutDurationChart extends StatelessWidget {
  final List<int> durations; // List of durations for the last 7 days (Mon-Sun)
  // streakCount is no longer used here

  const WorkoutDurationChart({
    super.key,
    required this.durations,
    // Removed streakCount parameter
  });

  // Define colors based on the new design
  static const Color barColor = Color(0xFFADFF2F); // Bright green
  static const Color textColor = Colors.grey; // Grey for axis labels
  static const Color backgroundColor = Colors.transparent; // Or match theme background

  @override
  Widget build(BuildContext context) {
    // Ensure we have exactly 7 days of data, padding with 0 if necessary
    List<double> weeklyData = List.generate(7, (index) {
      if (index < durations.length && durations[index] > 0) {
        return 1.0; // Represents a workout occurred
      } else {
        return 0.0; // Represents no workout
      }
    });

    return Padding(
      // Adjusted padding to better fit the new design without the old container
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: AspectRatio(
        // Adjust aspect ratio if needed for the new look
        aspectRatio: 1.8, 
        child: BarChart(
          BarChartData(
            backgroundColor: backgroundColor,
            gridData: const FlGridData(show: false), // Hide grid lines
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30, // Space for labels
                  getTitlesWidget: _getBottomTitles,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28, // Space for labels 0 and 1
                  interval: 1, // Show labels for 0 and 1
                  getTitlesWidget: _getLeftTitles,
                ),
              ),
              // Hide top and right titles
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false), // Hide chart border
            barTouchData: BarTouchData(enabled: false), // Disable touch interactions
            barGroups: _generateBarGroups(weeklyData),
            alignment: BarChartAlignment.spaceAround, // Distribute bars
             maxY: 1.2, // Set slightly higher than max value (1) for padding
          ),
        ),
      ),
    );
  }

  // Helper to generate bar groups from processed data
  List<BarChartGroupData> _generateBarGroups(List<double> data) {
    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index], // Use 0.0 or 1.0
            color: barColor,
            width: 18, // Adjust bar width as needed
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), // Round top corners
            // Removed backDrawRodData
          ),
        ],
         showingTooltipIndicators: [], // Ensure no tooltips are shown initially
      );
    });
  }

  // Helper for bottom axis titles (Days of Week)
  Widget _getBottomTitles(double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 0: text = 'Mon'; break;
      case 1: text = 'Tue'; break;
      case 2: text = 'Wed'; break;
      case 3: text = 'Thu'; break;
      case 4: text = 'Fri'; break;
      case 5: text = 'Sat'; break;
      case 6: text = 'Sun'; break;
      default: text = ''; break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4, // Space between bar and label
      child: Text(text, style: const TextStyle(color: textColor, fontSize: 12)),
    );
  }

  // Helper for left axis titles (0 and 1)
  Widget _getLeftTitles(double value, TitleMeta meta) {
     if (value == 0 || value == 1) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4, // Space between axis line and label
        child: Text(
          value.toInt().toString(),
           style: const TextStyle(color: textColor, fontSize: 12)
        ),
      );
    } 
    return Container(); // Return empty for other values
  }
}
