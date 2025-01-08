// lib/websocket_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:workout_logger/inventory/inventory_manager.dart';
import 'package:workout_logger/constants.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;

  WebSocketChannel? _channel;

  Function(List<Map<String, dynamic>>)? onInventoryUpdate;
  Function(double)? onCurrencyUpdate;

  WebSocketManager._internal();
  
  Future<void> connectWebSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');

    if (authToken == null) {
      print("No auth token found, skipping WebSocket connection");
      return;
    }

    _channel = WebSocketChannel.connect(
      Uri.parse(
        '${APIConstants.socketUrl}/ws/inventory/?token=$authToken',
      ),
    );

    _channel?.stream.listen(
      (message) {
        final decodedMessage = json.decode(message);
        if (decodedMessage is Map<String, dynamic>) {
          // Inventory updates
          if (decodedMessage['type'] == 'inventory_update') {
            final data = decodedMessage['data'];
            if (data is Map<String, dynamic>) {
              // Handle inventory items
              if (data['items'] is List) {
                final updatedItems = (data['items'] as List)
                    .map((item) => item as Map<String, dynamic>)
                    .toList();
                onInventoryUpdate?.call(updatedItems);
              }

              // Handle stats
              if (data['stats'] is Map<String, dynamic>) {
                final stats = data['stats'] as Map<String, dynamic>;
                InventoryManager().updateStats({
                  'strength': stats['strength'] ?? 0,
                  'agility': stats['agility'] ?? 0,
                  'intelligence': stats['intelligence'] ?? 0,
                  'stealth': stats['stealth'] ?? 0,
                  'speed': stats['speed'] ?? 0,
                  'defence': stats['defence'] ?? 0,
                });
              }
            }
          }
          // Currency updates
          if (decodedMessage['type'] == 'currency_update') {
            final data = decodedMessage['data'];
            if (data['currency'] is num) {
              print("Currency update received: ${data['currency']}");
              final double currencyValue = (data['currency'] as num).toDouble();
              onCurrencyUpdate?.call(currencyValue);
            }
          }

          if (decodedMessage['type'] == 'character_colors') {
            final data = decodedMessage['data'];
            print(data);
            if (data != null && data is Map<String, dynamic>) {
              InventoryManager().updateCharacterColors({
                'body_color': data['body_color']?.toString(),
                'eye_color': data['eye_color']?.toString(),
              });
            } else {
              print("Error: character_colors data is null or not a valid format");
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
    Future.delayed(const Duration(seconds: 20), () {
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

  Future<void> sendMessage(Map<String, dynamic> message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');
    print(authToken);
    print(_channel);
    if (authToken == null || _channel == null) {
      print("Cannot send message: No auth token or WebSocket not connected");
      return;
    }
    _channel!.sink.add(json.encode(message));
    print("WebSocket message sent: ${json.encode(message)}");
  }


}
