import 'package:flutter/material.dart';
import 'workout_page.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key, required this.currentPageIndex});

  final int currentPageIndex;

  static const List<Widget> _pages = <Widget>[
    Center(
      child: Text(
        'History Page',
        style: TextStyle(color: Colors.white),
      ),
    ),
    WorkoutPage(),
    Center(
      child: Text(
        'Exercises Page',
        style: TextStyle(color: Colors.white),
      ),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return _pages[currentPageIndex];
  }
}
