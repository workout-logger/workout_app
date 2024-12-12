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

  void _showProfileBottomSheet(Map<String, dynamic> userProfile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final characterImage = userProfile['characterImage'] ?? '';
        final username = userProfile['username'] ?? 'Unknown';

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arrow to close at the top center
                    Center(
                      child: IconButton(
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Fancy title
                    Center(
                      child: Text(
                        "$username's Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Character image
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          image: characterImage.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(characterImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: characterImage.isEmpty
                            ? Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 60,
                                ),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 30),
                    // Stats
                    Text(
                      "Stats",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildStatRow("Level", userProfile['stats']['level'].toString()),
                    _buildStatRow("Strength", userProfile['stats']['strength'].toString()),
                    _buildStatRow("Agility", userProfile['stats']['agility'].toString()),
                    _buildStatRow("Endurance", userProfile['stats']['endurance'].toString()),
                    SizedBox(height: 30),
                    // Items
                    Text(
                      "Items",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(height: 10),
                    ..._buildItemsList(userProfile['items'] ?? []),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildItemsList(List items) {
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          children: [
            Icon(Icons.chevron_right, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Text(
              item,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatRow(String statName, String statValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$statName:",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            statValue,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender_id'] == widget.userId;

    return GestureDetector(
      onTap: () {
        // Show bottom sheet with dummy data for now
        _showProfileBottomSheet({
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
            color: isMe ? Colors.grey[900] : Colors.grey[800],
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
                    color: Colors.white,
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
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
                  icon: Icon(Icons.send, color: Colors.white),
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
