import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:workout_logger/constants.dart';


class LastWorkoutView extends StatefulWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final String workoutDate;
  final int duration;
  final String averageHeartRate;
  final double energyBurned;
  final String muscleGroups;
  final String stats;

  const LastWorkoutView({
    super.key,
    this.animationController,
    this.animation,
    required this.workoutDate,
    required this.duration,
    required this.averageHeartRate,
    required this.energyBurned,
    required this.muscleGroups,
    required this.stats,
  });

  @override
  _LastWorkoutViewState createState() => _LastWorkoutViewState();
}

class _LastWorkoutViewState extends State<LastWorkoutView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Colors based on the image
    const Color bgColor = Color(0xFF0D0D0D); // Very dark background
    const Color cardBgColor = Color(0xFF1C1C1E); // Background for info boxes
    const Color accentGreen = Color(0xFF98FF00); // Bright lime green (Lime A400)
    // const Color darkGreen = Color(0xFF59B74C); // No longer needed for gradient
    const Color progressTrackColor = Color(0xFF303030); // Grey for progress track
    const Color textColorPrimary = Colors.white;
    const Color textColorSecondary = Color(0xFF8E8E93); // Grey for secondary text (iOS style grey)

    // Hardcoded values from the image for layout - Use actual data where possible
    // Use widget.energyBurned instead of hardcoded calBurned
    double calBurned = widget.energyBurned > 0 ? widget.energyBurned : 60.0; // Default if 0
    // Assuming a fixed target for now for the visual effect
    const double calTarget = 1108.0; // Example Target = Burned + Remaining (from image)
    double calRemaining = calTarget - calBurned > 0 ? calTarget - calBurned : 1048.0; // Calculate or use default
    double progress = 0.5;

    String displayDate = widget.workoutDate.isNotEmpty ? widget.workoutDate : "March 12"; // Default if empty
    if (displayDate != "March 12" && displayDate != "N/A") {
      try {
        DateTime date = DateTime.parse(displayDate);
        displayDate = "${_getMonthName(date.month)} ${date.day}";
      } catch (e) {
        // Keep original if parsing fails or it's already formatted
      }
    } else if (displayDate == "N/A") {
       displayDate = "March 12"; // Default if N/A
    }


    // Main widget structure
    return Container(
       // Use overall background color
      padding: const EdgeInsets.all(16.0),
       // Add padding around the whole card
      decoration: BoxDecoration(
        color: bgColor, // Use the main background color
        // Removed border radius from the main container if it's meant to be full width or part of a larger view
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
        children: <Widget>[
          // Header: "Last Workout" Button
          _buildLastWorkoutButton(textColorPrimary), // Removed gradient colors

          const SizedBox(height: 24), // Increased spacing

          // Top Row: Date, Calorie Circle, Cal Remaining
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Adjust horizontal padding if needed
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Date Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDate,
                      style: const TextStyle(
                        color: textColorPrimary,
                        fontSize: 17, // Slightly larger font size
                        fontWeight: FontWeight.w600, // Bold
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Date',
                      style: TextStyle(
                        color: textColorSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Calorie Circle - Using Stack to layer asset and painter
                SizedBox(
                  width: 120, // Increased circle size
                  height: 120, // Increased circle size
                  child: Stack( // Use Stack for layering
                    alignment: Alignment.center,
                    children: [
                       // Background Dashed Circle Asset (Assuming path assets/images/dashed_circle.png)
                      Image.asset(
                        'assets/images/dashed_circle.png',
                        fit: BoxFit.contain,

                      ),
                      // Progress Arc Painter
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          return CustomPaint(
                            size: size,
                            painter: _CalorieProgressPainter(
                              progress: progress,
                              backgroundColor: progressTrackColor,
                              progressColor: accentGreen,
                              strokeWidth: 15.0,
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255,152, 255, 0),
                                  Color.fromARGB(255, 112, 181, 10),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    calBurned.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22, // Decreased font size
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cal Burned',
                                    style: TextStyle(
                                      color: textColorSecondary,
                                      fontSize: 9, // Decreased font size
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ]
                  ),
                ),

                // Cal Remaining Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      calRemaining.toInt().toString(),
                      style: const TextStyle(
                        color: textColorPrimary,
                        fontSize: 17, // Match date font size
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                     const SizedBox(height: 4),
                    const Text(
                      'Cal Remaining',
                      style: TextStyle(
                        color: textColorSecondary,
                        fontSize: 13, // Match date subtitle
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24), // Increased spacing

          // Bottom Grid: 2x2 Info Boxes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0), // No extra padding for the grid container
            child: Column(
              children: [
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildInfoBox(
                        icon: Icons.fitness_center, // Dumbbell icon
                        title: 'Muscle Groups',
                        value: widget.muscleGroups.isNotEmpty ? widget.muscleGroups : 'Chest, Shoulder...', // Add ellipsis
                        accentColor: accentGreen,
                        textColorPrimary: textColorPrimary,
                        textColorSecondary: textColorSecondary,
                        cardBgColor: cardBgColor,
                      ),
                    ),
                    const SizedBox(width: 12), // Spacing between boxes
                    Expanded(
                      child: _buildInfoBox(
                        icon: Icons.timer, // Timer icon
                        title: 'Duration',
                        value: '${widget.duration} mins',
                        accentColor: accentGreen,
                        textColorPrimary: textColorPrimary,
                        textColorSecondary: textColorSecondary,
                         cardBgColor: cardBgColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Spacing between rows
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildInfoBox(
                        icon: Icons.favorite, // Heart icon
                        title: 'Avg Heart Rate',
                        // Use 'NA' from image if empty or invalid
                        value: widget.averageHeartRate.isNotEmpty && widget.averageHeartRate != 'null' ? widget.averageHeartRate : 'NA',
                        accentColor: accentGreen,
                        textColorPrimary: textColorPrimary,
                        textColorSecondary: textColorSecondary,
                         cardBgColor: cardBgColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        // Use info icon as per image
                        icon: Icons.info_outline, // Changed from show_chart
                        title: 'Stats Gained',
                        value: widget.stats.isNotEmpty ? widget.stats : '+2, +2, +2', // Default from image
                        accentColor: accentGreen,
                        textColorPrimary: textColorPrimary,
                        textColorSecondary: textColorSecondary,
                         cardBgColor: cardBgColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Removed extra SizedBox at the end if padding is handled by the main container
        ],
      ),
    );
  }

  // Helper to build the "Last Workout" button using the asset
  Widget _buildLastWorkoutButton(Color textColor) {
    return Container(
      height: 60, // Adjust height as needed
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        image: const DecorationImage( // Use DecorationImage for background
          image: AssetImage('assets/images/button_background.png'), // Asset path
          fit: BoxFit.fill, // Cover the container area
        ),
      ),
      child: Padding( // Padding for the text and icon inside
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Workout',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18, // Slightly larger
                    fontWeight: FontWeight.bold, // Bold
                  ),
                ),
                // Use Text for >>> icon
                
              ],
            ),
          ),
    );
  }


  // Helper to build the small info boxes
  Widget _buildInfoBox({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
    required Color textColorPrimary,
    required Color textColorSecondary,
    required Color cardBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14), // Slightly increased padding
      decoration: BoxDecoration(
        color: cardBgColor, // Use the card background color
        borderRadius: BorderRadius.circular(10), // Slightly more rounded
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: textColorSecondary,
              fontSize: 13, // Match secondary text size
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(icon, color: accentColor, size: 20), // Slightly larger icon
              const SizedBox(width: 8),
              Expanded( // Use Expanded to prevent overflow
                child: Text(
                  value,
                  style: TextStyle(
                    color: textColorPrimary,
                    fontSize: 15, // Slightly larger value text
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle long text
                  maxLines: 1, // Ensure single line
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

   // Helper to get month name from number
  String _getMonthName(int month) {
    // Using 3-letter month names as in the image
    const monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    if (month >= 1 && month <= 12) {
       return monthNames[month];
    }
    return ""; // Return empty string for invalid month
  }

  Future<void> _sendMuscleGroupUpdate(List<String> muscleGroups) async {
    final url = Uri.parse(APIConstants.updateLatestMuscleGroups);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $authToken',
      },
      body: jsonEncode({
        'muscleGroups': muscleGroups,
      }),
    );

    if (response.statusCode == 200) {
      print('Muscle groups updated successfully.');
    } else {
      print('Failed to update muscle groups. Status code: ${response.statusCode}');
    }
  }


  Future<String?> _showMuscleGroupDialog(BuildContext context) async {
    List<String> muscleGroupOptions = [
      'Calves', 'Hamstrings', 'Glutes', 'Chest', 'Quads',
      'Abs', 'Lats', 'Biceps', 'Shoulders', 'Triceps'
    ];
    List<String> selectedMuscleGroups = [];

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Select Muscle Groups',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: muscleGroupOptions.map((muscle) {
                    return CheckboxListTile(
                      title: Text(
                        muscle,
                        style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                      value: selectedMuscleGroups.contains(muscle),
                      activeColor: const Color.fromARGB(255, 255, 255, 255),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedMuscleGroups.add(muscle);
                          } else {
                            selectedMuscleGroups.remove(muscle);
                          }
                        });
                      },
                      checkColor: Colors.black,
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                  onPressed: () async {
                    Navigator.of(context).pop(selectedMuscleGroups.join(', '));
                    await _sendMuscleGroupUpdate(selectedMuscleGroups);

                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}




class CurvePainter extends CustomPainter {
  final double? angle;
  final List<Color>? colors;

  CurvePainter({this.colors, this.angle = 140});

  @override
  void paint(Canvas canvas, Size size) {
    List<Color> colorsList = [];
    if (colors != null && colors!.isNotEmpty) {
      colorsList = colors!;
    } else {
      colorsList.addAll([Colors.yellow, Colors.yellow]);
    }

    const double strokeWidth = 14.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width / 2, size.height / 2) - strokeWidth * 1.2;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    shadowPaint.color = Colors.grey.withOpacity(0.3);
    shadowPaint.strokeWidth = 16;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    shadowPaint.color = Colors.grey.withOpacity(0.2);
    shadowPaint.strokeWidth = 20;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    shadowPaint.color = Colors.grey.withOpacity(0.1);
    shadowPaint.strokeWidth = 22;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    final rect = Rect.fromCircle(center: center, radius: radius + strokeWidth / 2);
    final gradient = SweepGradient(
      startAngle: degreeToRadians(268),
      endAngle: degreeToRadians(270.0 + 360),
      tileMode: TileMode.repeated,
      colors: colorsList,
      stops: [0.0, angle! / 360, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      paint,
    );

    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const double circleRadius = strokeWidth / 2;
    final double endAngle = degreeToRadians(278 + (360 - (365 - angle!)));
    final Offset circleCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    canvas.drawCircle(circleCenter, circleRadius, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  double degreeToRadians(double degree) {
    return (math.pi / 180) * degree;
  }
}

// Custom Painter for the Calorie Circle - Modified to remove dashed circle drawing
class _CalorieProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color backgroundColor;
  final Color progressColor;
  final Gradient? gradient; // Add optional gradient parameter
  // final Color dashedColor; // No longer needed
  final double strokeWidth;

  _CalorieProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.gradient, // Initialize gradient parameter
    // required this.dashedColor, // No longer needed
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2; // Start from the top (12 o'clock)
    final sweepAngle = 2 * math.pi * progress;

    // Background track paint
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Progress arc paint
    final progressPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Rounded ends for the progress arc

    // Apply shader if gradient exists, otherwise apply solid color
    if (gradient != null) {
      progressPaint.shader = gradient!.createShader(rect);
    } else {
      progressPaint.color = progressColor;
    }

    // Draw background track (full circle)
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false, // Do not connect center
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieProgressPainter oldDelegate) {
     // Repaint if progress or colors change
    return oldDelegate.progress != progress ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.gradient != gradient; // Check gradient change
           // oldDelegate.dashedColor != dashedColor; // No longer needed
  }
}

// Custom Painter for Diagonal Lines Pattern - REMOVED as asset is used
// class _DiagonalLinesPainter extends CustomPainter {
//   final Color color;
//   final double strokeWidth;
//   final double spacing;
//
//   _DiagonalLinesPainter({
//     required this.color,
//     this.strokeWidth = 1.0,
//     this.spacing = 8.0, // Adjust spacing between lines
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke;
//
//     // Draw diagonal lines from top-left to bottom-right
//     // Adjust starting point and loop increment based on desired density/angle
//     double startX = -size.height; // Start drawing off-screen to cover corners
//     while (startX < size.width) {
//       canvas.drawLine(
//         Offset(startX, 0),
//         Offset(startX + size.height, size.height), // Lines at 45 degrees
//         paint,
//       );
//       startX += spacing; // Move to the next line start point
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _DiagonalLinesPainter oldDelegate) {
//     return oldDelegate.color != color ||
//            oldDelegate.strokeWidth != strokeWidth ||
//            oldDelegate.spacing != spacing;
//   }
// }

