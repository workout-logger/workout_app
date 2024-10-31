import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercise_model.dart';
import 'home_body.dart';
import 'fitness_app_theme.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'stopwatch_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseModel()),

      ],
      child: const MyApp(),
    ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExerciseModel>(
          create: (context) => ExerciseModel(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBody(
        currentPageIndex: _currentPageIndex,
        animationController: _animationController,
      ),
      bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,  // Add this line
      currentIndex: _currentPageIndex,
      onTap: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      backgroundColor: FitnessAppTheme.background,
      selectedItemColor: FitnessAppTheme.darkText,
      unselectedItemColor: FitnessAppTheme.deactivatedText,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/images/inventory_icon.svg',
            height: 24,
            color: Colors.white,
          ),
          label: 'Inventory',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.sync_alt), label: 'Trading'),
        const BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
      ],
    ),

    );
  }
}
