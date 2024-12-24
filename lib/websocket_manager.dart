import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;

  late WebSocketChannel _channel;
  Function(List<Map<String, dynamic>>)? onInventoryUpdate;

  WebSocketManager._internal() {
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');
    _channel = WebSocketChannel.connect(
      Uri.parse(
        'ws://jaybird-exciting-merely.ngrok-free.app/ws/inventory/?token=$authToken',
      ),
    );

    // Listen for messages
    _channel.stream.listen(
      (message) {
        final decodedMessage = json.decode(message);
        if (decodedMessage is Map<String, dynamic> &&
            decodedMessage['type'] == 'inventory_update') {
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
      _connectWebSocket();
    });
  }

  void setInventoryUpdateCallback(
      Function(List<Map<String, dynamic>>) callback) {
    onInventoryUpdate = callback;
  }

  void closeConnection() {
    _channel.sink.close(1000);
  }

  // New method to send messages
  void sendMessage(Map<String, dynamic> message) {
    try {
      _channel.sink.add(json.encode(message));
      print("WebSocket message sent: ${json.encode(message)}");
    } catch (e) {
      print("Error sending WebSocket message: $e");
    }
  }
}
