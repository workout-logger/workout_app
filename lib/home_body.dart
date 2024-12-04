import 'package:flutter/material.dart';
import 'home_diary.dart';
import 'profile_page.dart';
import 'inventory_page.dart';
import 'chat_page.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key, required this.currentPageIndex, required this.animationController});

  final int currentPageIndex;
  final AnimationController animationController;

  static List<Widget> _pages(AnimationController controller) => <Widget>[
        MyDiaryScreen(animationController: controller),
        const InventoryPage(),
        const ChatPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(BuildContext context) {
    return _pages(animationController)[currentPageIndex];
  }
}
