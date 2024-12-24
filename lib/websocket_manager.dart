import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;

  WebSocketChannel? _channel; // Make nullable to handle uninitialized cases
  Function(List<Map<String, dynamic>>)? onInventoryUpdate;
  Function(double)? onCurrencyUpdate; // Callback for currency updates

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

    // Listen for messages
    _channel?.stream.listen(
      (message) {
        final decodedMessage = json.decode(message);

        if (decodedMessage is Map<String, dynamic>) {
          // Handle inventory updates
          if (decodedMessage['type'] == 'inventory_update') {
            final data = decodedMessage['data'];
            if (data is Map<String, dynamic> && data['items'] is List) {
              final updatedItems = (data['items'] as List)
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              if (onInventoryUpdate != null) {
                onInventoryUpdate!(updatedItems);
              }
            }
          }

          // Handle currency updates
          if (decodedMessage['type'] == 'currency_update') {
            final data = decodedMessage['data'];
            print("Received currency_update message: $data");
            if (data['currency'] is num) {
              final double currencyValue = (data['currency'] as num).toDouble();
              print(onCurrencyUpdate != null);
              if (onCurrencyUpdate != null) {
                print("Invoking currency update callback with value: $currencyValue");
                onCurrencyUpdate!(currencyValue);
              }
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
    // Attempt to reconnect after a delay
    Future.delayed(const Duration(seconds: 5), () {
      print("Reconnecting to WebSocket...");
      connectWebSocket();
    });
  }

  // Callback setter for inventory updates
  void setInventoryUpdateCallback(
      Function(List<Map<String, dynamic>>) callback) {
    onInventoryUpdate = callback;
  }

  // Callback setter for currency updates
  void setCurrencyUpdateCallback(Function(double) callback) {
    onCurrencyUpdate = callback;
  }

  void closeConnection() {
    _channel?.sink.close(1000);
  }

  // Updated method to send messages safely
  void sendMessage(Map<String, dynamic> message) {
    try {
      if (_channel == null) {
        print("WebSocket not initialized. Cannot send message.");
        return;
      }
      _channel!.sink.add(json.encode(message));
      print("WebSocket message sent: ${json.encode(message)}");
    } catch (e) {
      print("Error sending WebSocket message: $e");
    }
  }
}
