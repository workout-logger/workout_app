import 'package:flutter/material.dart';
import 'package:workout_logger/trading_page.dart';
import 'package:animate_do/animate_do.dart'; // Import animate_do


class MMORPGMainScreen extends StatelessWidget {
  const MMORPGMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Updated to 4 tabs
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80), // Set height to fit TabBar
          child: AppBar(
            backgroundColor: Color.fromARGB(255, 0, 0, 0),
            elevation: 5,
            bottom: TabBar(
              indicatorColor: Color.fromARGB(255, 255, 255, 255),
              indicatorWeight: 3,
              labelColor: Color.fromARGB(255, 255, 255, 255),
              unselectedLabelColor: Colors.grey[500],
              tabs: [
                Tab(
                  icon: Icon(Icons.storefront_outlined),
                  text: 'Market',
                ),
                Tab(
                  icon: Icon(Icons.inventory_2_outlined),
                  text: 'Chests',
                ),
                Tab(
                  icon: Icon(Icons.chat_bubble_outline),
                  text: 'Chat',
                ),
                Tab(
                  icon: Icon(Icons.people_outline),
                  text: 'Friends',
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            MarketScreen(),
            ChestsScreen(), // New Chests Tab
            ChatPage(
              websocketUrl: 'ws://jaybird-exciting-merely.ngrok-free.app/ws/chat/?token=ca98303f6358d7df547dc515a5cd4315e6d4dd27', // Replace with your WebSocket URL
              username: 'johndoe', // Replace with authenticated username
              userId: '2', // Replace with authenticated user ID
            ),
            FriendsScreen(),
          ],
        ),
      ),
    );
  }
}

class ChestsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> chestData = [
    {'name': 'Bronze Chest', 'price': 100, 'number': 0},
    {'name': 'Silver Chest', 'price': 250, 'number': 1},
    {'name': 'Gold Chest', 'price': 500, 'number': 2},
    {'name': 'Diamond Chest', 'price': 1000, 'number': 3},
  ];

  const ChestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two items per row
            crossAxisSpacing: 16.0, // Space between columns
            mainAxisSpacing: 16.0, // Space between rows
          ),
          itemCount: chestData.length,
          itemBuilder: (context, index) {
            return ChestCard(
              chestName: chestData[index]['name'],
              chestPrice: chestData[index]['price'],
              chestNumber: chestData[index]['number'],
            );
          },
        ),
      ),
    );
  }
}



class MarketScreen extends StatelessWidget {
  final List<Map<String, dynamic>> globalItems = [
    {'name': 'Epic Sword', 'price': 1500, 'rarity': 'Epic'},
    {'name': 'Golden Shield', 'price': 1200, 'rarity': 'Legendary'},
    {'name': 'Mystic Helmet', 'price': 800, 'rarity': 'Rare'},
    {'name': 'Iron Boots', 'price': 300, 'rarity': 'Common'},
    {'name': 'Elven Bow', 'price': 1000, 'rarity': 'Rare'},
    {'name': 'Dragon Scale Armor', 'price': 2000, 'rarity': 'Legendary'},
    {'name': 'Hunter\'s Knife', 'price': 500, 'rarity': 'Common'},
    {'name': 'Wizard\'s Staff', 'price': 1800, 'rarity': 'Epic'},
  ];

  const MarketScreen({super.key});

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Common':
        return Colors.grey;
      case 'Rare':
        return Colors.blueGrey;
      case 'Epic':
        return Colors.deepPurple[300]!;
      case 'Legendary':
        return Colors.amber[300]!;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900], // Darker background
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: globalItems.length,
        itemBuilder: (context, index) {
          final item = globalItems[index];
          final rarityColor = _getRarityColor(item['rarity']);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2, // Subtle elevation
              color: Colors.grey[850], // Slightly lighter card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item['name']} tapped!')),
                  );
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0), // Reduced padding
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.grey[700], // Simpler placeholder
                            ),
                            child: const SizedBox(
                              height: 48, // Smaller placeholder
                              width: 48,
                              child: Icon(Icons.image_outlined, size: 24, color: Colors.white24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), // Less bold
                                ),
                                Text(
                                  item['rarity'],
                                  style: TextStyle(color: rarityColor.withOpacity(0.7), fontSize: 12), // More subtle color
                                ),
                              ],
                            ),
                          ),
                           Text(
                            "${item['price']} Coins",
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    // Animations
                    if (item['rarity'] == 'Legendary')
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    if (item['rarity'] == 'Epic')
                      Positioned.fill(
                        child: FadeIn(
                          duration: const Duration(milliseconds: 1000),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.deepPurple.withOpacity(0.2), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}





class GlobalItemRow extends StatelessWidget {
  final String itemName;
  final int itemPrice;
  final String itemRarity;

  const GlobalItemRow({
    super.key,
    required this.itemName,
    required this.itemPrice,
    required this.itemRarity,
  });

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Common':
        return Colors.grey;
      case 'Rare':
        return Colors.blue;
      case 'Epic':
        return Colors.purple;
      case 'Legendary':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.image_outlined, // Placeholder for item image
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      itemRarity,
                      style: TextStyle(
                        color: _getRarityColor(itemRarity),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "$itemPrice Coins",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Divider(
          color: Colors.grey,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
        ), // Separator
      ],
    );
  }
}


class ChestCard extends StatelessWidget {
  final String chestName;
  final int chestPrice;
  final int chestNumber;

  const ChestCard({
    super.key,
    required this.chestName,
    required this.chestPrice,
    required this.chestNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(0, 48, 48, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Handle chest purchase
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Purchase $chestName',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Do you want to buy this chest for $chestPrice coins?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$chestName purchased!',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text('Buy', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                child: Image.asset(
                  'assets/images/Pixel_Chest_Pack/chest_$chestNumber.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chestName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "$chestPrice Coins",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalChatScreen extends StatelessWidget {
  const GlobalChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 0, 0, 0),
      child: Center(
        child: Text(
          'Global Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 0, 0, 0),
      child: Center(
        child: Text(
          'Friends List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
