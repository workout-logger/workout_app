// lib/websocket_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;

  WebSocketChannel? _channel;

  Function(List<Map<String, dynamic>>)? onInventoryUpdate;
  Function(double)? onCurrencyUpdate;

  WebSocketManager._internal() {
    connectWebSocket();
  }

  Future<void> connectWebSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');

    _channel = WebSocketChannel.connect(
      Uri.parse(
        'ws://jaybird-exciting-merely.ngrok-free.app/ws/inventory/?token=$authToken',
      ),
    );

    _channel?.stream.listen(
      (message) {
        final decodedMessage = json.decode(message);
        if (decodedMessage is Map<String, dynamic>) {
          // Inventory updates
          if (decodedMessage['type'] == 'inventory_update') {
            final data = decodedMessage['data'];
            if (data is Map<String, dynamic> && data['items'] is List) {
              final updatedItems = (data['items'] as List)
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              onInventoryUpdate?.call(updatedItems);
            }
          }
          // Currency updates
          if (decodedMessage['type'] == 'currency_update') {
            final data = decodedMessage['data'];
            if (data['currency'] is num) {
              final double currencyValue = (data['currency'] as num).toDouble();
              onCurrencyUpdate?.call(currencyValue);
            }
          }
        }
      },
      onError: (error) {
        print("WebSocket Error: $error");
        _reconnectWebSocket();
      },
      onDone: () {
        print("WebSocket connection closed");
        _reconnectWebSocket();
      },
    );
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      print("Reconnecting to WebSocket...");
      connectWebSocket();
    });
  }

  void setInventoryUpdateCallback(
      Function(List<Map<String, dynamic>>) callback) {
    onInventoryUpdate = callback;
  }

  void setCurrencyUpdateCallback(Function(double) callback) {
    onCurrencyUpdate = callback;
  }

  void closeConnection() {
    _channel?.sink.close(1000);
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel == null) {
      print("WebSocket not initialized. Cannot send message.");
      return;
    }
    _channel!.sink.add(json.encode(message));
    print("WebSocket message sent: ${json.encode(message)}");
  }


}
