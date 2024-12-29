import 'package:workout_logger/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/inventory_manager.dart';
import 'package:workout_logger/lottie_segment_player.dart';
import 'package:workout_logger/websocket_manager.dart';
import 'ui_view/last_workout.dart';
import 'ui_view/title_view.dart';
import 'ui_view/workout_duration_chart.dart';
import 'ui_view/character_stats.dart';
import 'workout_tracking/workout_page.dart';
import 'workout_tracking/stopwatch_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart'; // For StopwatchProvider

class MyDiaryScreen extends StatefulWidget {
  const MyDiaryScreen({super.key, this.animationController});

  final AnimationController? animationController;

  @override
  _MyDiaryScreenState createState() => _MyDiaryScreenState();
}

class _MyDiaryScreenState extends State<MyDiaryScreen> with TickerProviderStateMixin {
  late final Animation<double> topBarAnimation;
  final List<Widget> listViews = <Widget>[];
  final ScrollController scrollController = ScrollController();

  double topBarOpacity = 0.0;

  // Workout fields
  List<int> weeklyWorkouts = [];
  String workoutDate = '';
  int duration = 0;
  int averageHeartRate = 0;
  double energyBurned = 0.0;
  int mood = 1;
  String muscleGroups = '';

  // Refresh / Pull-to-refresh state
  bool isRefreshing = false;
  double _pullDistance = 0.0;
  final double _refreshTriggerPullDistance = 150.0;

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

    // 1. Load or fetch workout data only if not already loaded
    SharedPreferences.getInstance().then((prefs) async {
      if (prefs.getString('latestWorkoutData') == null) {
        await fetchLatestWorkoutData();
        await prefs.setString('latestWorkoutData', json.encode({
          'workout_durations': weeklyWorkouts,
          'start_date': workoutDate,
          'duration': duration,
          'average_heart_rate': averageHeartRate,
          'totalEnergyBurned': energyBurned,
          'mood': mood,
          'muscleGroups': muscleGroups
        }));
      } else {
        final data = json.decode(prefs.getString('latestWorkoutData')!);
        updateStateFromData(data);
      }
    });

    // 2. Load or fetch inventory data (without setting the WebSocket callback)
    fetchEquippedItems();

    // 3. Control AppBar opacity
    scrollController.addListener(() {
      double offset = scrollController.offset;
      setState(() {
        topBarOpacity = offset >= 24 ? 1.0 : offset / 24;
      });
    });
  }

  /// Update local state with server or cached workout data
  void updateStateFromData([Map<String, dynamic>? data]) {
    setState(() {
      weeklyWorkouts = List<int>.from(
        data?['workout_durations'] ?? [0, 0, 0, 0, 0, 0, 0],
      );
      workoutDate = data?['start_date'] ?? '';
      duration = data?['duration'] ?? 0;
      averageHeartRate = data?['average_heart_rate'] ?? 0;
      energyBurned = data?['totalEnergyBurned'] ?? 0.0;
      mood = data?['mood'] ?? 1;
      muscleGroups = data?['muscleGroups'] ?? '';
      addAllListData();
    });
  }

  /// Only query inventory from SharedPreferences or request from server
  Future<void> fetchEquippedItems({bool forceRefresh = false}) async {

    // Check if data is already loaded
    if (!InventoryManager().isLoading) {
      // Data is already loaded, no need to set up the WebSocket callback again
      return;
    }

    // Register callback for inventory updates
    WebSocketManager().setInventoryUpdateCallback((updatedItems) {
      InventoryManager().updateInventory(updatedItems);
      if (mounted) {
        setState(() {});
      }
      // If we're refreshing, stop the refresh indicator
      if (isRefreshing) {
        isRefreshing = false;
      }
    });

    // Request the initial inventory data if loading
    InventoryManager().requestCharacterColors();

    InventoryManager().requestInventoryUpdate();
  }

  /// Load workout from local cache or fetch from server
  Future<void> fetchLatestWorkoutData({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedData = prefs.getString('latestWorkoutData');
      if (cachedData != null) {
        final data = json.decode(cachedData);
        updateStateFromData(data);
        return;
      }
    }

    // Otherwise fetch from the server
    const String apiUrl = APIConstants.lastWorkout;
    final String? authToken = prefs.getString('authToken');

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Token $authToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await prefs.setString('latestWorkoutData', response.body);
        updateStateFromData(data);
      } else {
        updateStateFromData();
      }
    } catch (e) {
      debugPrint('Error fetching latest workout data: $e');
    }
  }

  /// Build the main list of UI (character, stats, charts, etc.)
  void addAllListData() {
    const int count = 5;
    listViews.clear();

    // Read equipped items from InventoryManager
    final equipped = InventoryManager().equippedItems;
    final bodyColor = InventoryManager().bodyColor?? '';
    final eyeColors = InventoryManager().eyeColor?? '';
    // Extract file names
    final armorFile  = equipped['armour']  ?? '';
    final headFile   = equipped['heads']   ?? '';
    final legsFile   = equipped['legs']    ?? '';
    final meleeFile  = equipped['melee']   ?? '';
    final shieldFile = equipped['shield']  ?? '';
    final wingsFile  = equipped['wings']   ?? '';



    listViews.addAll([
      // Character stats
      CharacterStatsView(
        armor: armorFile,
        head: headFile,
        legs: legsFile,
        melee: meleeFile,
        shield: shieldFile,
        wings: wingsFile,
        baseBody: bodyColor,
        eyeColor: eyeColors,
        animation: createAnimation(0, count),
        animationController: widget.animationController!,
      ),
      TitleView(
        titleTxt: 'Last Workout',
        animation: createAnimation(1, count),
        animationController: widget.animationController!,
      ),
      LastWorkoutView(
        animation: createAnimation(2, count),
        animationController: widget.animationController!,
        workoutDate: workoutDate,
        duration: duration,
        averageHeartRate: averageHeartRate,
        energyBurned: energyBurned,
        mood: mood,
        muscleGroups: muscleGroups,
      ),
      TitleView(
        titleTxt: 'Workout Duration',
        subTxt: 'History',
        animation: createAnimation(3, count),
        animationController: widget.animationController!,
      ),
      WorkoutDurationChart(
        durations: weeklyWorkouts,
        streakCount: 7,
      ),
    ]);
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
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  /// Called when user does pull-to-refresh
  Future<void> handleRefresh() async {
    await fetchLatestWorkoutData(forceRefresh: true);
    await fetchEquippedItems(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 0, 0, 0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            getMainListViewUI(),
            getAppBarUI(),

            // The pull-to-refresh loading indicator
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
                  height: 50,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 99, 98, 98),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LottieSegmentPlayer(
                        animationPath: 'assets/animations/loading.json',
                        endFraction: 0.7,
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
        floatingActionButton: Consumer<StopwatchProvider>(
          builder: (context, stopwatchProvider, child) {
            return FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
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
              },
              label: stopwatchProvider.isRunning
                  ? Text(stopwatchProvider.formattedTime())
                  : const Text('Start Workout'),
              icon: const Icon(Icons.fitness_center),
            );
          },
        ),
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
                top: AppBar().preferredSize.height +
                    MediaQuery.of(context).padding.top +
                    24,
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

  /// Logic for custom pull-to-refresh
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0) {
        // Pulling past the top
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
        // Overscrolling at the top
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
    setState(() {
      isRefreshing = true;
    });
    handleRefresh().then((_) {
      setState(() {
        isRefreshing = false;
        _pullDistance = 0.0;
      });
    });
  }

  /// Simple AppBar with fade animation
  Widget getAppBarUI() {
    return Column(
      children: <Widget>[
        if (widget.animationController != null)
          AnimatedBuilder(
            animation: widget.animationController!,
            builder: (BuildContext context, Widget? child) {
              return FadeTransition(
                opacity: topBarAnimation,
                child: Transform(
                  transform: Matrix4.translationValues(
                    0.0,
                    30 * (1.0 - topBarAnimation.value),
                    0.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0)
                          .withOpacity(topBarOpacity),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32.0),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color.fromARGB(255, 68, 68, 68)
                              .withOpacity(0.4 * topBarOpacity),
                          offset: const Offset(1.1, 1.1),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16 - 8.0 * topBarOpacity,
                            bottom: 12 - 8.0 * topBarOpacity,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Home',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22 + 6 - 6 * topBarOpacity,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.account_circle, size: 30),
                                color: Colors.white,
                                onPressed: () {
                                  // Profile button logic here
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
