import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../fitness_app_theme.dart';
import 'package:hexcolor/hexcolor.dart';

class WorkoutDurationChart extends StatelessWidget {
  final List<int> durations; // List of durations over the last 10 days
  final int streakCount; // Streak count to display

  const WorkoutDurationChart({
    super.key,
    required this.durations,
    required this.streakCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 18,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: FitnessAppTheme.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8.0),
            bottomLeft: Radius.circular(8.0),
            bottomRight: Radius.circular(8.0),
            topRight: Radius.circular(68.0),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: FitnessAppTheme.grey.withOpacity(0.2),
              offset: const Offset(1.1, 1.1),
              blurRadius: 10.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20.0,
          ),
          child: Column(
            children: <Widget>[
              // Display Streak Count
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 36.0, bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Workout Streak',
                      style: TextStyle(
                        fontFamily: FitnessAppTheme.fontName,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: FitnessAppTheme.grey.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '$streakCount Days',
                      style: const TextStyle(
                        fontFamily: FitnessAppTheme.fontName,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: FitnessAppTheme.deactivatedText,
                      ),
                    ),
                  ],
                ),
              ),
              // The Bar Chart
              AspectRatio(
                aspectRatio: 1.7,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(0, 0, 0, 0), // Transparent background color
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BarChart(
                      BarChartData(
                        backgroundColor: const Color.fromARGB(0, 0, 0, 0), // Transparent background color
                        gridData: const FlGridData(show: false), // Hide grid lines
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Mon', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                  case 1:
                                    return const Text('Tue', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                  case 2:
                                    return const Text('Wed', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                  case 3:
                                    return const Text('Thu', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                  case 4:
                                    return const Text('Fri', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                  case 5:
                                    return const Text('Sat', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                  case 6:
                                    return const Text('Sun', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                  default:
                                    return const Text('', style: TextStyle(color: FitnessAppTheme.deactivatedText));
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 14,
                              getTitlesWidget: (value, _) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.white, // White text color
                                    fontWeight: FontWeight.w400,
                                    fontSize: 10, // Smaller font size
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false), // Hide right titles
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false), // Hide top titles
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false, // Hide borders
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} mins',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: '',
                                    style: TextStyle(
                                      color: Colors.grey[200],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          touchCallback: (FlTouchEvent event, barTouchResponse) {
                            if (event.isInterestedForInteractions &&
                                barTouchResponse != null &&
                                barTouchResponse.spot != null) {
                              final touchedSpot = barTouchResponse.spot!;
                              final x = touchedSpot.touchedBarGroup.x;
                              final y = touchedSpot.touchedBarGroup.barRods[0].toY;
                            }
                          },
                        ),
                        barGroups: List.generate(durations.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: durations[index].toDouble(),
                                color: HexColor('#fdfd96'),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
