import 'package:flutter/material.dart';
import 'models.dart';

class UserProfile extends StatelessWidget {
  final User user;

  // Sample inventory items
  final List<Item> inventory = [
    Item(
      id: 'item1',
      name: 'Sword',
      imageUrl: 'https://via.placeholder.com/100',
    ),
    Item(
      id: 'item2',
      name: 'Shield',
      imageUrl: 'https://via.placeholder.com/100',
    ),
    Item(
      id: 'item3',
      name: 'Potion',
      imageUrl: 'https://via.placeholder.com/100',
    ),
  ];

  UserProfile({super.key, required this.user});

  void _sendTradeRequest(BuildContext context) {
    // Placeholder for sending a trade request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trade request sent to ${user.name}!')),
    );
  }

  Widget _buildInventoryItem(Item item) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(item.name),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: inventory.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two items per row
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        return _buildInventoryItem(inventory[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('${user.name}\'s Profile'), backgroundColor: Colors.blue),
      body: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.avatarUrl),
          ),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          Expanded(child: _buildInventoryGrid()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _sendTradeRequest(context),
              child: const Text('Send Trade Request'),
            ),
          ),
        ],
      ),
    );
  }
}
