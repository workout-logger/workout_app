import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/inventory_manager.dart';
import 'package:workout_logger/lottie_segment_player.dart';
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
  bool _isLoading = true;

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

  bool get _hasRequiredData => 
    weeklyWorkouts.isNotEmpty;

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
  }

  Future<void> _initializeData() async {
    
    setState(() => _isLoading = true);
    
    try {
      // Set up WebSocket for inventory updates first
      WebSocketManager().setInventoryUpdateCallback((updatedItems) {
        if (!mounted) return;
        
        InventoryManager().updateInventory(updatedItems);
        setState(() {
          if (_hasRequiredData) {
            _isLoading = false;
            isRefreshing = false; // Also reset refresh state here
            _pullDistance = 0.0;
            addAllListData();
          }
        });
      });
      final prefs = await SharedPreferences.getInstance();

      // if (prefs.getInt('bodyColorIndex') == null || prefs.getInt('eyeColorIndex') == null) {
      InventoryManager().requestCharacterColors();
      final hasFetchedInventory = !(prefs.getBool('hasFetchedInventory') ?? false);
      if (hasFetchedInventory){
        InventoryManager().requestInventoryUpdate();
        prefs.setBool('hasFetchedInventory', true);
      }
      
      final cachedWorkout = prefs.getString('latestWorkoutData');
      
      if (cachedWorkout == null) {
        await fetchLatestWorkoutData();
      } else {
        updateStateFromData(json.decode(cachedWorkout));
      }

      // Check if we can show the UI yet
      if (mounted) {
        setState(() {
          if (_hasRequiredData) {
            _isLoading = false;
            addAllListData();
          }
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
      mood = data?['mood'] ?? 1;
      muscleGroups = data?['muscleGroups'] ?? '';
      
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

    if (!forceRefresh) {
      final cachedData = prefs.getString('latestWorkoutData');
      if (cachedData != null) {
        final data = json.decode(cachedData);
        updateStateFromData(data);
        return;
      }
    }

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

  Future<void> addAllListData() async {
    if (!mounted || !_hasRequiredData) return;
    
    const int count = 5;
    listViews.clear();

    // Safely get character data
    final equipped = InventoryManager().equippedItems;
    final bodyColor = InventoryManager().bodyColor;
    final eyeColors = InventoryManager().eyeColor;
    
    // Check if we have all required data
    if (bodyColor == null || eyeColors == null) {
      print('Missing required character data');
      return;
    }
    
    final armorFile = equipped['armour'] ?? '';
    final headFile = equipped['heads'] ?? '';
    final legsFile = equipped['legs'] ?? '';
    final meleeFile = equipped['melee'] ?? '';
    final shieldFile = equipped['shield'] ?? '';
    final wingsFile = equipped['wings'] ?? '';

    setState(() {
      listViews.addAll([
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
    return Container(
      color: const Color.fromARGB(255, 0, 0, 0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading || !_hasRequiredData
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Stack(
              children: <Widget>[
                getMainListViewUI(),
                getAppBarUI(),
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
