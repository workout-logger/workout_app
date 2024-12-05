import 'package:workout_logger/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui_view/body_measurement.dart';
import 'ui_view/last_workout.dart';
import 'ui_view/title_view.dart';
import 'ui_view/workout_duration_chart.dart';
import 'ui_view/character_stats.dart';
import 'workout_page.dart';
import 'stopwatch_provider.dart'; // Import StopwatchProvider
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart'; // Import Lottie

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
  List<int> weeklyWorkouts = [];
  String workoutDate = '';
  int duration = 0;
  int averageHeartRate = 0;
  double energyBurned = 0.0;
  int mood = 1;
  String muscleGroups = '';
  bool isRefreshing = false;
  double _pullDistance = 0.0;
  double _refreshTriggerPullDistance = 100.0;

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

    fetchLatestWorkoutData();
    fetchEquippedItems(); 

    scrollController.addListener(() {
      double offset = scrollController.offset;
      setState(() {
        topBarOpacity = offset >= 24 ? 1.0 : offset / 24;
      });
    });
  }

  void updateStateFromData(Map<String, dynamic> data) {
    setState(() {
      weeklyWorkouts = List<int>.from(data['workout_durations'] ?? [0, 0, 0, 0, 0, 0, 0]);
      workoutDate = data['start_date'] ?? '';
      duration = data['duration'] ?? 0;
      averageHeartRate = data['average_heart_rate'] ?? 0;
      energyBurned = data['totalEnergyBurned'] ?? 0.0;
      mood = data['mood'] ?? 0;
      muscleGroups = data['muscleGroups'] ?? '';
      addAllListData();
    });
  }

  Future<void> fetchEquippedItems({bool forceRefresh = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if data is already cached and refresh is not forced
    if (!forceRefresh) {
      String? cachedData = prefs.getString('equippedItemsData');
      if (cachedData != null) {
        final data = json.decode(cachedData);
        updateEquippedItems(data);
        return;
      }
    }

    const String apiUrl = APIConstants.equippedItems; // Adjust APIConstants to include this URL
    final String? authToken = prefs.getString('authToken');

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Token $authToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Save data locally
          await prefs.setString('equippedItemsData', response.body);

          updateEquippedItems(data);
        } else {
          print('Failed to fetch equipped items');
        }
      } else {
        print('Failed to fetch equipped items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching equipped items: $e');
    }
  }

  void updateEquippedItems(Map<String, dynamic> data) {
    final equippedItems = data['equipped_items'] ?? {};
    setState(() {
      if (listViews.isNotEmpty) {
        listViews[0] = CharacterStatsView(
          armor: equippedItems['armour'] ?? '',
          head: equippedItems['headpiece'] ?? '',
          legs: equippedItems['legs'] ?? '',
          melee: equippedItems['melee'] ?? '',
          shield: equippedItems['shield'] ?? '',
          wings: equippedItems['wings'] ?? '',
          animation: createAnimation(0, listViews.length),
          animationController: widget.animationController!,
        );
      }
    });
  }

  Future<void> fetchLatestWorkoutData({bool forceRefresh = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Check if data is already cached and refresh is not forced
    if (!forceRefresh) {
      String? cachedData = prefs.getString('latestWorkoutData');
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

        // Save data locally
        await prefs.setString('latestWorkoutData', response.body);

        updateStateFromData(data);
      } else {
        print('Failed to load latest workout data');
      }
    } catch (e) {
      print('Error fetching latest workout data: $e');
    }
  }

  void addAllListData() {
    const int count = 7;
    listViews.clear();
    listViews.addAll([
      CharacterStatsView(
        armor: '',
        head: '',
        legs: '',
        melee: '',
        shield: '',
        wings: '',
        animation: createAnimation(0, count),
        animationController: widget.animationController!,
      ),
      TitleView(
        titleTxt: 'Last Workout',
        subTxt: 'Details',
        animation: createAnimation(1, count),
        animationController: widget.animationController!,
      ),
      LastWorkoutView(
        animation: createAnimation(2, count),
        animationController: widget.animationController!,
        workoutDate: workoutDate, // Display the latest workout date
        duration: duration, // Display the workout duration
        averageHeartRate: averageHeartRate, // Display average heart rate
        energyBurned: energyBurned, // Display energy burned
        mood: mood, // Display the mood
        muscleGroups: muscleGroups,
      ),
      TitleView(
        titleTxt: 'Workout Duration',
        subTxt: 'Last 7 days',
        animation: createAnimation(3, count),
        animationController: widget.animationController!,
      ),
      WorkoutDurationChart(
        durations: weeklyWorkouts,
        streakCount: 7,
      ),
      TitleView(
        titleTxt: 'Body measurement',
        subTxt: 'Today',
        animation: createAnimation(6, count),
        animationController: widget.animationController!,
      ),
      BodyMeasurementView(
        animation: createAnimation(7, count),
        animationController: widget.animationController!,
      )
    ]);
  }

  Animation<double> createAnimation(int index, int count) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController!,
        curve: Interval((1 / count) * index, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );
  }

  Future<bool> getData() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  Future<void> handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });
    await fetchLatestWorkoutData(forceRefresh: true);
    await fetchEquippedItems(forceRefresh: true);
    setState(() {
      isRefreshing = false;
      _pullDistance = 0.0;
    });
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
            if (_pullDistance > 0 || isRefreshing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  alignment: Alignment.topCenter,
                  height: _pullDistance > _refreshTriggerPullDistance
                      ? _refreshTriggerPullDistance
                      : _pullDistance,
                  child: SizedBox(
                    width: 50, // Adjust the size as needed
                    height: 50,
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
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
  physics: const AlwaysScrollableScrollPhysics(), // Add this line
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
      }
    } else if (notification is OverscrollNotification) {
      setState(() {
        _pullDistance += notification.overscroll;
      });
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
                      0.0, 30 * (1.0 - topBarAnimation.value), 0.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0).withOpacity(topBarOpacity),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32.0),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color.fromARGB(255, 68, 68, 68).withOpacity(0.4 * topBarOpacity),
                          offset: const Offset(1.1, 1.1),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).padding.top,
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16 - 8.0 * topBarOpacity,
                              bottom: 12 - 8.0 * topBarOpacity),
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
                                      color: const Color.fromARGB(255, 255, 255, 255),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_left),
                                color: Colors.grey,
                                onPressed: () {},
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '15 May',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right),
                                color: Colors.grey,
                                onPressed: () {},
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
