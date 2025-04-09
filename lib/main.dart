// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:workout_logger/inventory/inventory_provider.dart';
import 'package:workout_logger/currency_provider.dart';
import 'package:workout_logger/refresh_notifier.dart';
import 'package:workout_logger/websocket_manager.dart';

import 'package:workout_logger/workout_tracking/exercise_model.dart';
import 'package:workout_logger/workout_tracking/stopwatch_provider.dart';
import 'package:workout_logger/onboarding/login_screen.dart';
import 'home_body.dart';
import 'fitness_app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'onboarding/google_signin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('firstLaunch') ?? false;
  final String? authToken = prefs.getString('authToken');

  // Create providers
  final inventoryProvider = InventoryProvider();
  final currencyProvider = CurrencyProvider();



  if (authToken != null) {
    WebSocketManager().setInventoryUpdateCallback((updatedItems) {
      inventoryProvider.updateInventory(updatedItems);
    });

    WebSocketManager().setCurrencyUpdateCallback((value) {
      currencyProvider.updateCurrency(value);
    });

    await WebSocketManager().connectWebSocket();
  }


  // Start the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseModel()),
        ChangeNotifierProvider.value(value: currencyProvider),
        ChangeNotifierProvider.value(value: inventoryProvider),
        ChangeNotifierProvider(create: (_) => RefreshNotifier()),
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

    // Example usage of Providers (if needed)
    final currencyProv = Provider.of<CurrencyProvider>(context, listen: false);
    final inventoryProv = Provider.of<InventoryProvider>(context, listen: false);
    // currencyProv.currentValue, inventoryProv.items, etc.
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Constants for layout
    const double navBarHeight = 55.0;
    const double inactiveIconHeight = 35.0;
    const double activeIconWidth = 75.0;
    const double activeIconHeight = 66.0;
    const double activeIconTranslateY = -9.0;
    const double containerTopPosition = 15.0;
    const double containerBottomPosition = -25.0;
    const double iconTopPosition = 2.0;
    const double labelBottomPosition = -2.0;
    const double activeIconSize = 40.0;
    const double labelFontSize = 12.0;
    const Color labelColor = Color(0xFFADFF2F);
    final LinearGradient activeBackgroundColor = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.fromARGB(255, 23, 138, 0),
        Color.fromARGB(45, 17, 109, 1),
      ],
    );
    const BorderRadius containerBorderRadius = BorderRadius.all(Radius.circular(10.0));

    return Scaffold(
      body: HomeBody(
        currentPageIndex: _currentPageIndex,
        animationController: _animationController,
      ),
      // ---------------------------------------------------------
      // 1) Wrap in a Stack so icons can overflow upward
      // 2) The Container enforces a 60px bar, but the child (bar)
      //    is transparent + iconSize=0 so it won't fight us on height.
      // ---------------------------------------------------------
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          // The colored area at the bottom with nominal 60px height
          Container(
            height: navBarHeight,
            color: FitnessAppTheme.background,
          ),
          // Position the real bottom nav on top of that Container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,

              // -----------------------------
              // The KEY to removing overflow:
              // Turn off default icon/label sizing entirely,
              // then do all custom icon/label layout in the items.
              // -----------------------------
              iconSize: 0, // Let your custom stack icons handle sizing
              selectedFontSize: 0,
              unselectedFontSize: 0,
              selectedLabelStyle: const TextStyle(fontSize: 0),
              unselectedLabelStyle: const TextStyle(fontSize: 0),
              showSelectedLabels: false,
              showUnselectedLabels: false,

              currentIndex: _currentPageIndex,
              onTap: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },

              // Provide custom icons inside each item:
              items: [
                BottomNavigationBarItem(
                  label: '', // No built-in label
                  // This is the "inactive" icon
                  icon: Image.asset(
                    'assets/images/icons/neon_green_home_deactivated.png',
                    height: inactiveIconHeight,
                  ),
                  // This is the "active" icon with custom layout
                  activeIcon: Transform.translate(
                    offset: const Offset(0, activeIconTranslateY),
                    child: SizedBox(
                      width: activeIconWidth,
                      height: activeIconHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                          // A negative top pushes the container up above the parent's top edge
                          top: containerTopPosition, 
                          left: 0,
                          right: 0,
                          bottom: containerBottomPosition,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: activeBackgroundColor,
                              borderRadius: containerBorderRadius,
                            ),
                          ),
                        ),

                          Positioned(
                            top: iconTopPosition,
                            child: Image.asset(
                              'assets/images/icons/neon_green_home.png',
                              height: activeIconSize,
                              width: 45,
                            ),
                          ),
                          Positioned(
                            bottom: labelBottomPosition,
                            child: const Text(
                              'Home',
                              style: TextStyle(
                                fontSize: labelFontSize,
                                color: labelColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BottomNavigationBarItem(
                  label: '',
                  icon: Image.asset(
                    'assets/images/icons/inventory.png',
                    height: inactiveIconHeight,
                  ),
                  activeIcon: Transform.translate(
                    offset: const Offset(0, activeIconTranslateY),
                    child: SizedBox(
                      width: activeIconWidth,
                      height: activeIconHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: containerTopPosition,
                            left: 0,
                            right: 0,
                            bottom: containerBottomPosition,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: activeBackgroundColor,
                                borderRadius: containerBorderRadius,
                              ),
                            ),
                          ),
                          Positioned(
                            top: iconTopPosition,
                            child: Image.asset(
                              'assets/images/icons/inventory_activated.png',
                              height: activeIconSize,
                            ),
                          ),
                          Positioned(
                            bottom: labelBottomPosition,
                            child: const Text(
                              'Inventory',
                              style: TextStyle(
                                fontSize: labelFontSize,
                                color: labelColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BottomNavigationBarItem(
                  label: '',
                  icon: Image.asset(
                    'assets/images/icons/chest.png',
                    height: inactiveIconHeight,
                  ),
                  activeIcon: Transform.translate(
                    offset: const Offset(0, activeIconTranslateY),
                    child: SizedBox(
                      width: activeIconWidth,
                      height: activeIconHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: containerTopPosition,
                            left: 0,
                            right: 0,
                            bottom: containerBottomPosition,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: activeBackgroundColor,
                                borderRadius: containerBorderRadius,
                              ),
                            ),
                          ),
                          Positioned(
                            top: iconTopPosition,
                            child: Image.asset(
                              'assets/images/icons/chest_activated.png',
                              height: activeIconSize,
                            ),
                          ),
                          Positioned(
                            bottom: labelBottomPosition,
                            child: const Text(
                              'Trading',
                              style: TextStyle(
                                fontSize: labelFontSize,
                                color: labelColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BottomNavigationBarItem(
                  label: '',
                  icon: Image.asset(
                    'assets/images/icons/dungeon.png',
                    height: inactiveIconHeight,
                  ),
                  activeIcon: Transform.translate(
                    offset: const Offset(0, activeIconTranslateY),
                    child: SizedBox(
                      width: activeIconWidth,
                      height: activeIconHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: containerTopPosition,
                            left: 0,
                            right: 0,
                            bottom:containerBottomPosition,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: activeBackgroundColor,
                                borderRadius: containerBorderRadius,
                              ),
                            ),
                          ),
                          Positioned(
                            top: iconTopPosition,
                            child: Image.asset(
                              'assets/images/icons/dungeon_activated.png',
                              height: activeIconSize,
                            ),
                          ),
                          Positioned(
                            bottom: labelBottomPosition,
                            child: const Text(
                              'Dungeon',
                              style: TextStyle(
                                fontSize: labelFontSize,
                                color: labelColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}