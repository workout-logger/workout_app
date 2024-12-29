// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:workout_logger/inventory_provider.dart';
import 'package:workout_logger/currency_provider.dart';
import 'package:workout_logger/websocket_manager.dart';

import 'package:workout_logger/workout_tracking/exercise_model.dart';
import 'package:workout_logger/workout_tracking/stopwatch_provider.dart';
import 'package:workout_logger/login_screen.dart';
import 'home_body.dart';
import 'fitness_app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'google_signin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;
  final String? authToken = prefs.getString('authToken');

  // Create providers
  final inventoryProvider = InventoryProvider();
  final currencyProvider = CurrencyProvider();

  // Set WebSocket callback for inventory
  WebSocketManager().setInventoryUpdateCallback((updatedItems) {
    inventoryProvider.updateInventory(updatedItems);
  });

  // If you want currency updates
  WebSocketManager().setCurrencyUpdateCallback((value) {
    currencyProvider.updateCurrency(value);
  });

  // Start the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseModel()),
        ChangeNotifierProvider.value(value: currencyProvider),
        ChangeNotifierProvider.value(value: inventoryProvider),
      ],
      child: MyApp(
        isFirstLaunch: isFirstLaunch,
        authToken: authToken,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  final String? authToken;

  const MyApp({
    super.key,
    required this.isFirstLaunch,
    required this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      // If it's the first launch, show Google Sign-In, otherwise show HomeScreen
      home: authToken == null || isFirstLaunch
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}

// lib/home_screen.dart


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Example: if you want the current currency
    final currencyProv = Provider.of<CurrencyProvider>(context, listen: false);
    final inventoryProv = Provider.of<InventoryProvider>(context, listen: false);

    // Now currencyProv.currentValue or inventoryProv.items is accessible
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
        type: BottomNavigationBarType.fixed,
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/inventory_icon.svg',
              height: 24,
              color: Colors.white,
            ),
            label: 'Inventory',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.sync_alt),
            label: 'Trading',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
