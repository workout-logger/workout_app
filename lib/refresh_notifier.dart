// refresh_notifier.dart
import 'package:flutter/material.dart';

class RefreshNotifier extends ChangeNotifier {
  void requestRefresh() {
    notifyListeners();
  }
}
