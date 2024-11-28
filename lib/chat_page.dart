import 'package:flutter/material.dart';
import 'package:workout_logger/fitness_app_theme.dart';
import 'models.dart';
import 'user_profile.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Sample users
  final User currentUser = User(
    id: '1',
    name: 'You',
    avatarUrl: 'https://via.placeholder.com/150',
  );

  final List<User> users = [
    User(
      id: '2',
      name: 'Alice',
      avatarUrl: 'https://via.placeholder.com/150/FF5733',
    ),
    User(
      id: '3',
      name: 'Bob',
      avatarUrl: 'https://via.placeholder.com/150/33FF57',
    ),
  ];

  // Sample messages
  final List<Message> messages = [];

  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      messages.add(
        Message(
          sender: currentUser,
          content: _messageController.text.trim(),
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
    });
  }

  Widget _buildMessage(Message message) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          // Navigate to user profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfile(user: message.sender),
            ),
          );
        },
        child: CircleAvatar(
          backgroundImage: NetworkImage(message.sender.avatarUrl),
        ),
      ),
      title: Text(
        message.sender.name,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        message.content,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Text(
        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _buildMessage(messages[messages.length - 1 - index]);
      },
    );
  }

Widget _buildMessageInput() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    color: FitnessAppTheme.white, // Lighter shade than black
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter message...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            onSubmitted: (value) => _sendMessage(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.white),
          onPressed: _sendMessage,
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Global Chat Room',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatList()),
          const Divider(height: 1, color: Colors.white),
          _buildMessageInput(),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
