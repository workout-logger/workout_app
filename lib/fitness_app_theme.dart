import 'package:flutter/material.dart';

class FitnessAppTheme {
  FitnessAppTheme._();
  static const Color nearlyWhite = Color(0xFF1A1A1A);
  static const Color white = Color(0xFF2C2C2C);
  static const Color background = Color.fromARGB(255, 0, 0, 0);
  static const Color nearlyDarkBlue = Color.fromARGB(255, 255, 255, 255);

  static const Color nearlyBlue = Color.fromARGB(255, 255, 255, 255);
  static const Color nearlyBlack = Color(0xFF121212);
  static const Color grey = Color.fromARGB(255, 199, 197, 197);
  static const Color dark_grey = Color.fromARGB(255, 255, 254, 254);

  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkerText = Color(0xFFCCCCCC);
  static const Color lightText = Color.fromARGB(255, 219, 218, 218);
  static const Color deactivatedText = Color.fromARGB(255, 173, 169, 169);
  static const Color dismissibleBackground = Color(0xFF1A1A1A);
  static const Color spacer = Color(0xFF2A2A2A);

  static const String fontName = 'Roboto';

  static const TextStyle display1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 36,
    letterSpacing: 0.4,
    height: 0.9,
    color: darkerText,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.27,
    color: darkerText,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: 0.18,
    color: darkerText,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: -0.04,
    color: darkText,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.2,
    color: darkText,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -0.05,
    color: darkText,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
    color: lightText, // was lightText
  );
}
