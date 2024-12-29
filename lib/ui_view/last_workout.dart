import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../fitness_app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:workout_logger/constants.dart';


class LastWorkoutView extends StatefulWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final String workoutDate;
  final int duration;
  final int averageHeartRate;
  final double energyBurned;
  final int mood;
  final String muscleGroups;

  const LastWorkoutView({
    super.key,
    this.animationController,
    this.animation,
    required this.workoutDate,
    required this.duration,
    required this.averageHeartRate,
    required this.energyBurned,
    required this.mood,
    required this.muscleGroups,
  });

  @override
  _LastWorkoutViewState createState() => _LastWorkoutViewState();
}

class _LastWorkoutViewState extends State<LastWorkoutView> {
  late String muscleGroups;

  @override
  void initState() {
    super.initState();
    muscleGroups = widget.muscleGroups;
  }

@override
Widget build(BuildContext context) {
  // Dynamically check if all values are zero
  bool isAllZero = (widget.duration == 0 &&
      widget.averageHeartRate == 0 &&
      widget.energyBurned == 0);

  return AnimatedBuilder(
    animation: widget.animationController!,
    builder: (BuildContext context, Widget? child) {
      return FadeTransition(
        opacity: widget.animation!,
        child: Transform(
          transform: Matrix4.translationValues(
            0.0,
            30 * (1.0 - widget.animation!.value),
            0.0,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 18),
            child: Stack(
              children: [
                // Main workout widget
                Container(
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
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 25, right: 16, left: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  height: 48,
                                  width: 2,
                                  decoration: BoxDecoration(
                                    color: HexColor('#87A0E5').withOpacity(0.5),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Muscle Groups',
                                        style: TextStyle(
                                          fontFamily: FitnessAppTheme.fontName,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          letterSpacing: -0.1,
                                          color: FitnessAppTheme.grey.withOpacity(0.5),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 24,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            const Icon(Icons.fitness_center,
                                                color: FitnessAppTheme.darkerText, size: 24),
                                            const SizedBox(width: 8),
                                            Text(
                                              muscleGroups.isNotEmpty ? muscleGroups : 'None',
                                              style: const TextStyle(
                                                fontFamily: FitnessAppTheme.fontName,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: FitnessAppTheme.darkerText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 40.0),
                              child: Text(
                                widget.workoutDate,
                                style: const TextStyle(
                                  fontFamily: FitnessAppTheme.fontName,
                                  fontSize: 18,
                                  color: FitnessAppTheme.deactivatedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 24, right: 24, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _buildInfoRow('Duration', Icons.timer, '${widget.duration} mins'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Avg Heart Rate', Icons.favorite, '${widget.averageHeartRate} bpm'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Mood', Icons.mood, String.fromCharCode(widget.mood)),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16, bottom: 70),
                            child: Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: FitnessAppTheme.white,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(100.0),
                                        ),
                                        border: Border.all(
                                          width: 4,
                                          color: FitnessAppTheme.nearlyDarkBlue.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            '${(widget.energyBurned * widget.animation!.value).toInt()}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: FitnessAppTheme.fontName,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 24,
                                              letterSpacing: 0.0,
                                              color: FitnessAppTheme.nearlyDarkBlue,
                                            ),
                                          ),
                                          Text(
                                            'Cal Burned',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: FitnessAppTheme.fontName,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 0.0,
                                              color: FitnessAppTheme.grey.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isAllZero)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                          topRight: Radius.circular(68.0),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'No Workout History',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: FitnessAppTheme.fontName,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
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
    },
  );
}


  Widget _buildInfoRow(String label, IconData icon, String value) {
    return Row(
      children: <Widget>[
        Container(
          height: 48,
          width: 2,
          decoration: BoxDecoration(
            color: HexColor('#F56E98').withOpacity(0.5),
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: FitnessAppTheme.fontName,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    letterSpacing: -0.1,
                    color: FitnessAppTheme.grey.withOpacity(0.5),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Icon(icon, color: FitnessAppTheme.darkerText),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: FitnessAppTheme.fontName,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: FitnessAppTheme.darkerText,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
