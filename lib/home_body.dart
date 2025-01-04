import 'package:flutter/material.dart';
import 'home_diary.dart';
import 'profile_page.dart';
import 'inventory_page.dart';
import 'marketplace.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({
    Key? key,
    required this.currentPageIndex,
    required this.animationController,
  }) : super(key: key);

  final int currentPageIndex;
  final AnimationController animationController;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    // Create the pages only once
    pages = [
      MyDiaryScreen(animationController: widget.animationController),
      InventoryPage(),
      MMORPGMainScreen(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentPageIndex,
      children: pages,
    );
  }
}
