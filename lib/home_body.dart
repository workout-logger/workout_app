import 'package:flutter/material.dart';
import 'workout_page.dart';
import 'home_diary.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key, required this.currentPageIndex, required this.animationController});

  final int currentPageIndex;
  final AnimationController animationController;

  static List<Widget> _pages(AnimationController controller) => <Widget>[
        MyDiaryScreen(animationController: controller),
        WorkoutPage(),
        Center(
          child: Text(
            'Exercises Page',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return _pages(animationController)[currentPageIndex];
  }
}
