import 'dart:async';
import 'package:flutter/material.dart';

class StopwatchProvider with ChangeNotifier {
  late Stopwatch _stopwatch;
  late Timer _timer;
  int _elapsedMilliseconds = 0;

  StopwatchProvider() {
    _stopwatch = Stopwatch();
  }

  int get elapsedMilliseconds => _elapsedMilliseconds;
  bool get isRunning => _stopwatch.isRunning;
  String formattedTime() {
    final int hours = (_elapsedMilliseconds ~/ 3600000) % 24;
    final int minutes = (_elapsedMilliseconds ~/ 60000) % 60;
    final int seconds = (_elapsedMilliseconds ~/ 1000) % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }


  void startStopwatch({int initialMilliseconds = 0}) {
    _elapsedMilliseconds = initialMilliseconds;
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
        notifyListeners();
      });
    }
  }

  void stopStopwatch() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer.cancel();
    }
    notifyListeners();
  }

  void resetStopwatch() {
    stopStopwatch();
    _stopwatch.reset();
    _elapsedMilliseconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
