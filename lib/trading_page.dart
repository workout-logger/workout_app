import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String websocketUrl;
  final String token;

  const ChatPage({
    Key? key,
    required this.websocketUrl,
    required this.token,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  WebSocketChannel? channel;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  void _initializeWebSocket() async {
    try {
      // Add token to WebSocket URL
      final wsUrl = widget.websocketUrl;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Set a timeout for initial connection
      bool connected = false;
      Future.delayed(const Duration(seconds: 10), () {
        if (!connected && mounted) {
          setState(() {
            _error = 'Connection timeout';
            _isLoading = false;
          });
          _reconnect();
        }
      });

      channel?.stream.listen(
        (data) {
          connected = true;
          _handleMessage(data);
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = 'Connection error: $error';
              _isLoading = false;
              _isConnected = false;
            });
            _reconnect();
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
            _reconnect();
          }
        },
      );

      // Only fetch history after successful connection
      _fetchChatHistory();
      
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to connect: $e';
          _isLoading = false;
          _isConnected = false;
        });
        _reconnect();
      }
    }
  }

  void _handleMessage(dynamic data) {
    if (!mounted) return;

    try {
      final decodedData = json.decode(data);

      setState(() {
        switch (decodedData['type']) {
          case 'chat_history':
            _messages.clear();
            _messages.addAll(List<Map<String, dynamic>>.from(decodedData['messages']));
            _isLoading = false;
            break;
          case 'chat_message':
            _messages.add(decodedData);
            break;
          case 'error':
            _error = decodedData['message'];
            _isLoading = false;
            break;
        }
      });
    } catch (e) {
      print('Error processing message: $e');
      setState(() {
        _error = 'Error processing message';
        _isLoading = false;
      });
    }
  }

  void _reconnect() {
    if (!mounted || _isConnected) return;
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isConnected) {
        _initializeWebSocket();
      }
    });
  }

  void _fetchChatHistory() {
    if (channel != null && _isConnected) {
      final payload = {
        "action": "fetch",
      };
      channel?.sink.add(json.encode(payload));
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && channel != null && _isConnected) {
      final payload = {
        "action": "send",
        "message": message,
      };

      try {
        channel?.sink.add(json.encode(payload));
        _messageController.clear();
      } catch (e) {
        setState(() {
          _error = 'Failed to send message';
        });
      }
    }
  }

  @override
  void dispose() {
    channel?.sink.close(status.normalClosure);
    _messageController.dispose();
    super.dispose();
  }

  // Rest of the UI code remains the same...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          if (!_isConnected && _error != null)
            Container(
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _initializeWebSocket,
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(
                          _messages[_messages.length - 1 - index]);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isConnected ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
   Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isCurrentUser = message['is_current_user']; // Assuming token is user ID
    
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue[700] : Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(maxWidth: 280), // Limit bubble width
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser) // Only show username for other users' messages
              Text(
                message['username'] ?? 'Anonymous',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            Text(
              message['message'] ?? '',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              message['timestamp'] != null
                  ? message['timestamp'].toString().split('T')[1].split('.')[0]
                  : '',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}