import 'package:flutter/material.dart';

class TradingPage extends StatefulWidget {
  const TradingPage({super.key});

  @override
  _TradingPageState createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Mocked message list

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({"user": "You", "message": text});
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Trading Chatroom",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.grey[850],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              reverse: true, // Show latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ListTile(
                  title: Text(
                    message["user"]!,
                    style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    message["message"]!,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          // Input field and send button
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.greenAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to initiate a trade
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.grey[850],
                title: const Text(
                  "Initiate Trade",
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select item to trade:",
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      dropdownColor: Colors.grey[850],
                      items: <String>['Item 1', 'Item 2', 'Item 3'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (_) {},
                      hint: const Text("Choose item", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Action to confirm trade
                        Navigator.of(context).pop();
                        setState(() {
                          _messages.add({
                            "user": "System",
                            "message": "Trade request sent. Waiting for confirmation."
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                      ),
                      child: const Text("Send Trade Request"),
                    ),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.swap_horiz),
      ),
    );
  }
}
