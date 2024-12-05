import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_model.dart';
import 'home_body.dart';
import 'fitness_app_theme.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'stopwatch_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'google_signin_page.dart'; // Import your Google sign-in page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('firstLaunch') ?? false; // Defaults to true if not set
  final String? authToken = prefs.getString('authToken');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseModel()),
      ],
      child: MyApp(isFirstLaunch: isFirstLaunch && authToken == null), // Show sign-in only if first launch and no token
    ),
  );
}


class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // If it's the first launch, show Google Sign-In page, otherwise show HomeScreen
      home: GoogleSignInPage(),
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
