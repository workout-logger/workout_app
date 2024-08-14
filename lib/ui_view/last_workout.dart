import '../fitness_app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hexcolor/hexcolor.dart';

class LastWorkoutView extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final String workoutDate;

  const LastWorkoutView({
    Key? key,
    this.animationController,
    this.animation,
    required this.workoutDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - animation!.value), 0.0),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 16, bottom: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: FitnessAppTheme.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                      topRight: Radius.circular(68.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: FitnessAppTheme.grey.withOpacity(0.2),
                        offset: Offset(1.1, 1.1),
                        blurRadius: 10.0),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 16, right: 16, left: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                height: 48,
                                width: 2,
                                decoration: BoxDecoration(
                                  color: HexColor('#87A0E5')
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(4.0)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, bottom: 2),
                                      child: Text(
                                        'Muscle Groups',
                                        style: TextStyle(
                                          fontFamily:
                                              FitnessAppTheme.fontName,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          letterSpacing: -0.1,
                                          color: FitnessAppTheme.grey
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: <Widget>[
                                        Icon(Icons.fitness_center,
                                            color: FitnessAppTheme
                                                .darkerText),
                                        SizedBox(width: 8),
                                        Text(
                                          'Chest, Triceps',
                                          style: TextStyle(
                                            fontFamily: FitnessAppTheme
                                                .fontName,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: FitnessAppTheme
                                                .darkerText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 30.0, top: 5), // Adjust the value as needed
                            child: Text(
                              workoutDate,
                              style: TextStyle(
                                fontFamily: FitnessAppTheme.fontName,
                                fontSize: 18,
                                color: FitnessAppTheme.deactivatedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 24, right: 24, top: 4),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    height: 48,
                                    width: 2,
                                    decoration: BoxDecoration(
                                      color: HexColor('#F56E98')
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(4.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, bottom: 2),
                                          child: Text(
                                            'Duration',
                                            style: TextStyle(
                                              fontFamily: FitnessAppTheme
                                                  .fontName,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              letterSpacing: -0.1,
                                              color: FitnessAppTheme.grey
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Icon(Icons.timer,
                                                color: FitnessAppTheme
                                                    .darkerText),
                                            SizedBox(width: 8),
                                            Text(
                                              '45 mins',
                                              style: TextStyle(
                                                fontFamily: FitnessAppTheme
                                                    .fontName,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: FitnessAppTheme
                                                    .darkerText,
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Container(
                                    height: 48,
                                    width: 2,
                                    decoration: BoxDecoration(
                                      color: HexColor('#F56E98')
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(4.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, bottom: 2),
                                          child: Text(
                                            'Avg Heart Rate',
                                            style: TextStyle(
                                              fontFamily: FitnessAppTheme
                                                  .fontName,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              letterSpacing: -0.1,
                                              color: FitnessAppTheme.grey
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Icon(Icons.favorite,
                                                color: FitnessAppTheme
                                                    .darkerText),
                                            SizedBox(width: 8),
                                            Text(
                                              '120 bpm',
                                              style: TextStyle(
                                                fontFamily: FitnessAppTheme
                                                    .fontName,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: FitnessAppTheme
                                                    .darkerText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Container(
                                    height: 48,
                                    width: 2,
                                    decoration: BoxDecoration(
                                      color: HexColor('#F56E98')
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(4.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, bottom: 2),
                                          child: Text(
                                            'Mood',
                                            style: TextStyle(
                                              fontFamily: FitnessAppTheme
                                                  .fontName,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              letterSpacing: -0.1,
                                              color: FitnessAppTheme.grey
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Icon(Icons.mood,
                                                color: FitnessAppTheme
                                                    .darkerText),
                                            SizedBox(width: 8),
                                            Text(
                                              '😊',
                                              style: TextStyle(
                                                fontFamily: FitnessAppTheme
                                                    .fontName,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 24,
                                                color: FitnessAppTheme
                                                    .darkerText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                          )
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
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(100.0),
                                      ),
                                      border: Border.all(
                                          width: 4,
                                          color: FitnessAppTheme.nearlyDarkBlue
                                              .withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '${(1200 * animation!.value).toInt()}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: FitnessAppTheme
                                                .fontName,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 24,
                                            letterSpacing: 0.0,
                                            color: FitnessAppTheme
                                                .nearlyDarkBlue,
                                          ),
                                        ),
                                        Text(
                                          'Kcal Burned',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: FitnessAppTheme
                                                .fontName,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 0.0,
                                            color: FitnessAppTheme.grey
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CustomPaint(
                                    painter: CurvePainter(
                                      colors: [
                                        const Color.fromARGB(255, 255, 255, 255),
                                        HexColor("#fdfd96"),
                                        HexColor("#fdfd96"),
                                      ],
                                      angle: 140 +
                                          (360 - 140) *
                                              (1.0 - animation!.value),
                                    ),
                                    child: SizedBox(
                                      width: 130,
                                      height: 130,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, top: 8, bottom: 8),
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          color: FitnessAppTheme.background,
                          borderRadius:
                              BorderRadius.all(Radius.circular(4.0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      // Set the colors to yellow for the completed part of the arc
      colorsList.addAll([Colors.yellow, Colors.yellow]);
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    final shadowPaintCenter = Offset(size.width / 2, size.height / 2);
    final shadowPaintRadius = math.min(size.width / 2, size.height / 2) - (14 / 2);
    canvas.drawArc(
      Rect.fromCircle(center: shadowPaintCenter, radius: shadowPaintRadius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    shadowPaint.color = Colors.grey.withOpacity(0.3);
    shadowPaint.strokeWidth = 16;
    canvas.drawArc(
      Rect.fromCircle(center: shadowPaintCenter, radius: shadowPaintRadius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    shadowPaint.color = Colors.grey.withOpacity(0.2);
    shadowPaint.strokeWidth = 20;
    canvas.drawArc(
      Rect.fromCircle(center: shadowPaintCenter, radius: shadowPaintRadius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    shadowPaint.color = Colors.grey.withOpacity(0.1);
    shadowPaint.strokeWidth = 22;
    canvas.drawArc(
      Rect.fromCircle(center: shadowPaintCenter, radius: shadowPaintRadius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      shadowPaint,
    );

    final rect = Rect.fromLTWH(0.0, 0.0, size.width, size.width);
    final gradient = SweepGradient(
      startAngle: degreeToRadians(268),
      endAngle: degreeToRadians(270.0 + 360),
      tileMode: TileMode.repeated,
      colors: colorsList,
      stops: [0.0, angle! / 360, 1.0], // Ensure the stops match the colors length
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - (14 / 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle!)),
      false,
      paint,
    );

    final gradient1 = SweepGradient(
      tileMode: TileMode.repeated,
      colors: [Colors.white, Colors.white],
    );

    var cPaint = Paint();
    cPaint..shader = gradient1.createShader(rect);
    cPaint..color = Colors.white;
    cPaint..strokeWidth = 14 / 2;
    canvas.save();

    final centerToCircle = size.width / 2;
    canvas.save();

    canvas.translate(centerToCircle, centerToCircle);
    canvas.rotate(degreeToRadians(angle! + 2));

    canvas.save();
    canvas.translate(0.0, -centerToCircle + 14 / 2);
    canvas.drawCircle(Offset(0, 0), 14 / 5, cPaint);

    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  double degreeToRadians(double degree) {
    return (math.pi / 180) * degree;
  }
}
