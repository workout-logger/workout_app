import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String websocketUrl;
  final String username; // Authenticated user's username
  final String userId; // Authenticated user's ID

  ChatPage({
    required this.websocketUrl,
    required this.username,
    required this.userId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late WebSocketChannel channel;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true; // Indicates whether messages are loading

  @override
  void initState() {
    super.initState();
    // Initialize WebSocket connection
    channel = WebSocketChannel.connect(Uri.parse(widget.websocketUrl));

    // Request chat history upon connection
    _fetchChatHistory();

    // Listen for incoming messages
    channel.stream.listen((data) {
      final decodedData = json.decode(data);

      // Check the type of incoming data
      if (decodedData['type'] == 'chat_history') {
        // Handle chat history response
        setState(() {
          _messages.addAll(List<Map<String, dynamic>>.from(decodedData['messages']));
          _isLoading = false; // Loading complete
        });
      } else if (decodedData['type'] == 'chat_message') {
        // Handle new incoming messages
        setState(() {
          _messages.add(decodedData);
        });
      }
    });
  }

  // Function to fetch chat history
  void _fetchChatHistory() {
    final payload = {
      "action": "fetch", // Indicating the action to fetch chat history
    };

    // Send the fetch request to the WebSocket server
    channel.sink.add(json.encode(payload));
  }

  @override
  void dispose() {
    channel.sink.close(status.normalClosure);
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // Create the message payload
      final payload = {
        "sender_id": widget.userId,
        "message": message,
      };

      // Send the message to the WebSocket server
      channel.sink.add(json.encode(payload));

      // Optionally, add the message locally to the UI
      setState(() {
        _messages.add({
          "sender_id": widget.userId,
          "username": widget.username,
          "message": message,
          "timestamp": DateTime.now().toIso8601String(),
        });
      });

      // Clear the input field
      _messageController.clear();
    }
  }

  void _showProfilePopup(BuildContext context, Map<String, dynamic> userProfile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "${userProfile['username']}'s Profile",
            style: TextStyle(color: Colors.tealAccent),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Character Display
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(userProfile['characterImage']),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.tealAccent, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Stats Section
                Text(
                  "Stats:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Level: ${userProfile['stats']['level']}\n"
                  "Strength: ${userProfile['stats']['strength']}\n"
                  "Agility: ${userProfile['stats']['agility']}\n"
                  "Endurance: ${userProfile['stats']['endurance']}",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),

                // Items Section
                Text(
                  "Items:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                SizedBox(height: 10),
                ...userProfile['items'].map<Widget>((item) {
                  return Text(
                    "- $item",
                    style: TextStyle(color: Colors.white),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Close",
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender_id'] == widget.userId;

    return GestureDetector(
      onTap: () {
        // Show profile popup with dummy data for now
        _showProfilePopup(context, {
          'username': message['username'] ?? 'Anonymous',
          'characterImage': 'https://via.placeholder.com/100', // Replace with actual character image URL
          'stats': {
            'level': 10,
            'strength': 15,
            'agility': 12,
            'endurance': 14,
          },
          'items': ['Sword', 'Shield', 'Potion'],
        });
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.blueGrey[700] : Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  message['username'] ?? 'Anonymous',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
              Text(
                message['message'] ?? '',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 5),
              Text(
                message['timestamp'] != null
                    ? message['timestamp'].toString().split('T')[1].split('.')[0]
                    : '',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Messages List or Loading Spinner
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
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

          // Message Input Field
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.tealAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
