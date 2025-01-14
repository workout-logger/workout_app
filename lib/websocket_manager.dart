// lib/websocket_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:workout_logger/dungeon/dungeon_manager.dart';
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
      return;
    }

    _channel = WebSocketChannel.connect(
      Uri.parse('${APIConstants.socketUrl}/ws/inventory/?token=$authToken'),
    );

    _channel?.stream.listen(
      (message) {
        // print("Raw WebSocket message received: $message");  // Add this line
        final decodedMessage = json.decode(message);
        if (decodedMessage is Map<String, dynamic>) {
          final String? msgType = decodedMessage['type'];

          // ------------------- Existing Logic ------------------- //
          if (msgType == 'inventory_update') {
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
          } else if (msgType == 'currency_update') {
            final data = decodedMessage['data'];
            if (data['currency'] is num) {
              final double currencyValue = (data['currency'] as num).toDouble();
              onCurrencyUpdate?.call(currencyValue);
            }
          } else if (msgType == 'character_colors') {
            final data = decodedMessage['data'];
            if (data != null && data is Map<String, dynamic>) {
              InventoryManager().updateCharacterColors({
                'body_color': data['body_color']?.toString(),
                'eye_color': data['eye_color']?.toString(),
              });
            }
          }

          // ------------------- NEW Dungeon Messages ------------------- //
          else if (msgType == 'dungeon_started') {
            DungeonManager().onDungeonStarted(decodedMessage);
          } else if (msgType == 'dungeon_stopped') {
            DungeonManager().onDungeonStopped(decodedMessage);
          } else if (msgType == 'dungeon_event') {
            DungeonManager().onDungeonEvent(decodedMessage);
          } else if (msgType == 'choice_feedback') {
            DungeonManager().onChoiceFeedback(decodedMessage);
          } else if (msgType == 'dungeon_reward') {
            DungeonManager().onDungeonReward(decodedMessage);
          }else if (msgType == 'dungeon_data') {
            DungeonManager().onDungeonData(decodedMessage);
          }
        }
      },
      onError: (error) {
        _reconnectWebSocket();
      },
      onDone: () {
        _reconnectWebSocket();
      },
    );
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 20), () {
      connectWebSocket();
    });
  }

  void setInventoryUpdateCallback(Function(List<Map<String, dynamic>>) callback) {
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
    if (authToken == null || _channel == null) {
      return;
    }
    _channel!.sink.add(json.encode(message));
  }
}
