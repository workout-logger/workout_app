import 'package:flutter/material.dart';
import 'websocket_manager.dart';

class CurrencyProvider with ChangeNotifier {
  double _currency = 0.0;

  double get currency => _currency;

  CurrencyProvider() {
    print("CurrencyProvider initialized");
    WebSocketManager().setCurrencyUpdateCallback((double newCurrency) {
      print('CurrencyProvider: Updating currency to: $newCurrency');
      updateCurrency(newCurrency);
    });

    // Immediately request the initial currency data
    WebSocketManager().sendMessage({
      'action': 'fetch_currency_data',
    });
  }

  void updateCurrency(double newCurrency) {
    print('CurrencyProvider: Updating currency to $newCurrency');
    _currency = newCurrency;
    notifyListeners();
  }



  @override
  void dispose() {
    WebSocketManager().closeConnection(); // Close WebSocket when disposed
    super.dispose();
  }
}
