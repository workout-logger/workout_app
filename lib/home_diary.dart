import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/inventory/inventory_manager.dart';
import 'package:workout_logger/lottie_segment_player.dart';
import 'package:workout_logger/refresh_notifier.dart';
import 'package:workout_logger/websocket_manager.dart';
import 'package:workout_logger/constants.dart';
import 'ui_view/last_workout.dart';
import 'ui_view/title_view.dart';
import 'ui_view/workout_duration_chart.dart';
import 'ui_view/character_stats.dart';
import 'workout_tracking/workout_page.dart';
import 'workout_tracking/stopwatch_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:workout_logger/ui_view/current_dungeon.dart';

class MyDiaryScreen extends StatefulWidget {
  const MyDiaryScreen({super.key, this.animationController});

  final AnimationController? animationController;

  @override
  MyDiaryScreenState createState() => MyDiaryScreenState();
}

class MyDiaryScreenState extends State<MyDiaryScreen> with TickerProviderStateMixin {
  late final Animation<double> topBarAnimation;
  final List<Widget> listViews = <Widget>[];
  final ScrollController scrollController = ScrollController();
  bool _isLoading = true;

  double topBarOpacity = 0.0;

  // Workout fields
  List<int> weeklyWorkouts = [];
  String workoutDate = '';
  int duration = 0;
  int averageHeartRate = 0;
  double energyBurned = 0.0;
  String stats_gained = '';
  String muscleGroups = '';

  // Refresh / Pull-to-refresh state
  bool isRefreshing = false;
  double _pullDistance = 0.0;
  final double _refreshTriggerPullDistance = 150.0;
  
  bool get _hasRequiredData => 
    InventoryManager().hasCharacterData;

  // Placeholder variables for user info - replace with actual data fetching
  String userName = "Alex Pltnkov"; 
  int userCoins = 500;

  @override
  void initState() {
    super.initState();

    if (widget.animationController != null) {
      topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: widget.animationController!,
          curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
        ),
      );
    }

    // Initialize data
    _initializeData();

    scrollController.addListener(() {
      double offset = scrollController.offset;
      setState(() {
        topBarOpacity = offset >= 24 ? 1.0 : offset / 24;
      });
    });

    final refreshNotifier = Provider.of<RefreshNotifier>(context, listen: false);
    refreshNotifier.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    final refreshNotifier = Provider.of<RefreshNotifier>(context, listen: false);
    refreshNotifier.removeListener(_onExternalRefresh);
    super.dispose();
  }
  
  Future<void> _initializeData() async {
    
    setState(() => _isLoading = true);
    
    try {

      final prefs = await SharedPreferences.getInstance();
      
      await InventoryManager().requestCharacterColors();
      await InventoryManager().requestInventoryUpdate();
      await _waitForDataAvailability();

      
      await fetchLatestWorkoutData();


      // Check if we can show the UI yet
      if (_hasRequiredData && mounted) {
        setState(() {
          _isLoading = false;
          addAllListData();
        });
      }

    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _waitForDataAvailability() async {
    const int maxRetries = 20; // Maximum number of retries
    const Duration retryInterval = Duration(milliseconds: 500); // Retry interval

    int retries = 0;
    while (retries < maxRetries) {
      // Check if the required data is available
      if (InventoryManager().hasCharacterData) {
        return; // Data is ready, exit the loop
      }

      // Wait for the next retry interval
      await Future.delayed(retryInterval);

      retries++;
    }

    // If the maximum retries are exceeded, log a warning
    debugPrint('Warning: Data not available after maximum retries.');
  }

  void updateStateFromData([Map<String, dynamic>? data]) {
    if (!mounted) return;
    
    setState(() {
      weeklyWorkouts = List<int>.from(
        data?['workout_durations'] ?? [0, 0, 0, 0, 0, 0, 0],
      );
      workoutDate = data?['start_date'] ?? '';
      duration = data?['duration'] ?? 0;
      averageHeartRate = data?['average_heart_rate'] ?? 0;
      energyBurned = data?['totalEnergyBurned'] ?? 0.0;
      stats_gained = data?['stats'] ?? '';
      
      // Get muscle groups and show only first 2 with ellipsis
      String fullMuscleGroups = data?['muscleGroups'] ?? '';
      List<String> muscles = fullMuscleGroups.split(',');
      muscleGroups = fullMuscleGroups.length <= 15
          ? fullMuscleGroups
          : '${fullMuscleGroups.substring(0,15)}...';
      
      // Only call addAllListData if we have character data
      if (_hasRequiredData) {
        addAllListData();
      }
    });
  }

  Future<void> fetchEquippedItems({bool forceRefresh = false}) async {
    // Always request updates on refresh
    if (forceRefresh || InventoryManager().isLoading) {
      InventoryManager().requestCharacterColors();
      InventoryManager().requestInventoryUpdate();
    }
  }

  Future<void> fetchLatestWorkoutData({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    const String apiUrl = APIConstants.lastWorkout;
    final String? authToken = prefs.getString('authToken');

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Token $authToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        updateStateFromData(data);
      } else {
        updateStateFromData();
      }
    } catch (e) {
      debugPrint('Error fetching latest workout data: $e');
    }
  }

  Future<void> addAllListData() async {
    if (!mounted || !_hasRequiredData) return;
    
    const int count = 5;
    listViews.clear();

    // Safely get character data
    final equipped = InventoryManager().equippedItems;
    final bodyColor = InventoryManager().bodyColor;
    final eyeColors = InventoryManager().eyeColor;
    final stats = (InventoryManager().stats ?? {}).map((key, value) {
      return MapEntry(key, int.tryParse(value.toString()) ?? 0); // Convert to int or default to 0
    });
    
    // Check if we have all required data
    if (bodyColor == null || eyeColors == null) {
      return;
    }
    
    final armorFile = equipped['armour'] ?? '';
    final headFile = equipped['heads'] ?? '';
    final legsFile = equipped['legs'] ?? '';
    final meleeFile = equipped['melee'] ?? '';
    final armsFile = equipped['arm'] ?? '';
    final wingsFile = equipped['wings'] ?? '';

    setState(() {
      listViews.addAll([
        CharacterStatsView(
          armor: armorFile,
          head: headFile,
          legs: legsFile,
          melee: meleeFile,
          arms: armsFile,
          wings: wingsFile,
          baseBody: bodyColor,
          eyeColor: eyeColors,
          stats: stats,
          animation: createAnimation(0, count),
          animationController: widget.animationController!,
        ),
        LastWorkoutView(
          animation: createAnimation(1, count),
          animationController: widget.animationController!,
          workoutDate: workoutDate,
          duration: duration,
          averageHeartRate: "NA",
          energyBurned: energyBurned,
          stats: stats_gained,
          muscleGroups: muscleGroups,
        ),
        _buildSectionHeader('Current Dungeon'),
        CurrentDungeonView(
           animation: createAnimation(2, count),
           animationController: widget.animationController!,
           distanceRun: 23, // Example data
           recentEvent: "Killed a Goblin!", // Example data
           currentHealth: 75, // Example data
           maxHealth: 100,
         ),
        _buildSectionHeader('Workout Streak', showHistory: true),
        WorkoutDurationChart(
          durations: weeklyWorkouts,
        ),
      ]);
    });
  }

  Animation<double> createAnimation(int index, int count) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController!,
        curve: Interval(
          (1 / count) * index,
          1.0,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );
  }

  Future<bool> getData() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return true;
  }

  void _onExternalRefresh() {
    _startRefresh();
  }

  Future<void> handleRefresh() async {
    if (isRefreshing) return; // Prevent multiple refreshes
    
    setState(() {
      isRefreshing = true;
    });

    try {
      // Reset character data loading state
      InventoryManager().isLoading = true;
      
      // Request new data
      await Future.wait([
        fetchLatestWorkoutData(forceRefresh: true),
        fetchEquippedItems(forceRefresh: true)
      ]);


      if (mounted) {
        setState(() {
          isRefreshing = false;
          _pullDistance = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error during refresh: $e');
      if (mounted) {
        setState(() {
          isRefreshing = false;
          _pullDistance = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Ensure the background is black
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/sword.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                repeat: true,
              ),
            )
          : ListenableBuilder(
              listenable: InventoryManager(),
              builder: (context, child) {
                final inventoryManager = InventoryManager();
                final hasAllData = _hasRequiredData && inventoryManager.hasCharacterData;
                
                return !hasAllData
                    ? Container() // Optionally, handle this case differently
                    : Stack(
                        children: <Widget>[
                          getMainListViewUI(),
                          // getAppBarUI(),
                          if (_pullDistance > 0 || isRefreshing)
                            Positioned(
                              top: (_pullDistance > _refreshTriggerPullDistance
                                  ? _refreshTriggerPullDistance / 2
                                  : _pullDistance / 2) +
                                  AppBar().preferredSize.height +
                                  MediaQuery.of(context).padding.top,
                              left: 0,
                              right: 0,
                              child: Container(
                                alignment: Alignment.topCenter,
                                height: 60,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 0.6,
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: LottieSegmentPlayer(
                                      animationPath: 'assets/animations/refresh.json',
                                      endFraction: 1,
                                      width: 108,
                                      height: 108,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: MediaQuery.of(context).padding.bottom),
                        ],
                      );
              },
            ),
      floatingActionButton: _isLoading
          ? null // Hide FAB while loading
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return const Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.95,
                        child: WorkoutPage(),
                      ),
                    );
                  },
                );

                if (result == true) {
                  _startRefresh();
                }
              },
              label: const Text('Start Workout'),
              icon: const Icon(Icons.fitness_center),
              backgroundColor: const Color(0xFFADFF2F),
              foregroundColor: Colors.black,
            ),
    );
  }

  Widget getMainListViewUI() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: FutureBuilder<bool>(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          } else {
            return ListView.builder(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: AppBar().preferredSize.height,
                bottom: 62 + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: listViews.length,
              itemBuilder: (BuildContext context, int index) {
                widget.animationController?.forward();
                return listViews[index];
              },
            );
          }
        },
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0) {
        setState(() {
          _pullDistance = -notification.metrics.pixels;
        });
      } else if (notification.metrics.pixels >= 0 && _pullDistance != 0.0) {
        setState(() {
          _pullDistance = 0.0;
        });
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        setState(() {
          _pullDistance += -notification.overscroll;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_pullDistance >= _refreshTriggerPullDistance && !isRefreshing) {
        _startRefresh();
      } else {
        setState(() {
          _pullDistance = 0.0;
        });
      }
    }
    return false;
  }

  void _startRefresh() {
    if (isRefreshing) return; // Prevent multiple refreshes
    handleRefresh();
  }

  Widget _buildSectionHeader(String title, {bool showHistory = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showHistory)
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History navigation not implemented yet.')),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'History',
                    style: TextStyle(
                      color: Color(0xFFADFF2F),
                      fontSize: 14,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFFADFF2F), size: 20),
                  Icon(Icons.chevron_right, color: Color(0xFFADFF2F), size: 20),
                  Icon(Icons.chevron_right, color: Color(0xFFADFF2F), size: 20),
                ],
              ),
            )
          else
           InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title navigation not implemented yet.')),
                );
              },
             child: const Row(
               children: [
                 Icon(Icons.chevron_right, color: Color(0xFFADFF2F), size: 20),
                 Icon(Icons.chevron_right, color: Color(0xFFADFF2F), size: 20),
                 Icon(Icons.chevron_right, color: Color(0xFFADFF2F), size: 20),
               ],
             ),
           ),
        ],
      ),
    );
  }

  /// Simple AppBar with fade animation
  // Widget getAppBarUI() {
  //   return Column(
  //     children: <Widget>[
  //       if (widget.animationController != null)
  //         AnimatedBuilder(
  //           animation: widget.animationController!,
  //           builder: (BuildContext context, Widget? child) {
  //             return FadeTransition(
  //               opacity: topBarAnimation,
  //               child: Transform(
  //                 transform: Matrix4.translationValues(
  //                   0.0,
  //                   30 * (1.0 - topBarAnimation.value),
  //                   0.0,
  //                 ),
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     color: const Color.fromARGB(255, 0, 0, 0)
  //                         .withOpacity(1.0),
  //                   ),
  //                   child: Column(
  //                     children: <Widget>[
  //                       SizedBox(height: MediaQuery.of(context).padding.top),
  //                       Padding(
  //                         padding: const EdgeInsets.only(
  //                           left: 16,
  //                           right: 16,
  //                           top: 8,
  //                           bottom: 8,
  //                         ),
  //                         child: Row(
  //                           children: <Widget>[
  //                             Row(
  //                               children: [
  //                                 const CircleAvatar(
  //                                   radius: 18,
  //                                   backgroundColor: Colors.grey,
  //                                   child: Icon(Icons.person, size: 20, color: Colors.white),
  //                                 ),
  //                                 const SizedBox(width: 8),
  //                                 Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.start,
  //                                   children: [
  //                                     Text(
  //                                       userName,
  //                                       style: const TextStyle(
  //                                         color: Colors.white,
  //                                         fontWeight: FontWeight.bold,
  //                                         fontSize: 14,
  //                                       ),
  //                                     ),
  //                                     Row(
  //                                       children: [
  //                                         const Icon(Icons.monetization_on, color: Colors.orangeAccent, size: 16),
  //                                         const SizedBox(width: 4),
  //                                         Text(
  //                                           '$userCoins Coins',
  //                                           style: const TextStyle(
  //                                             color: Colors.orangeAccent,
  //                                             fontSize: 12,
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                             Expanded(
  //                               child: Text(
  //                                 'Fitquest',
  //                                 textAlign: TextAlign.center,
  //                                 style: TextStyle(
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 20,
  //                                   letterSpacing: 1.0,
  //                                   color: Colors.white,
  //                                 ),
  //                               ),
  //                             ),
  //                             IconButton(
  //                               icon: const Icon(Icons.more_vert, size: 28),
  //                               color: Colors.white,
  //                               onPressed: () {
  //                                 ScaffoldMessenger.of(context).showSnackBar(
  //                                   const SnackBar(
  //                                     content: Text('Menu not implemented yet.'),
  //                                     backgroundColor: Colors.black,
  //                                     duration: Duration(seconds: 2),
  //                                   ),
  //                                 );
  //                               },
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //     ],
  //   );
  // }
  
}
