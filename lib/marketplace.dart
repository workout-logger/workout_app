import 'package:flutter/material.dart';
import 'package:workout_logger/trading_page.dart';

class MMORPGMainScreen extends StatelessWidget {
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
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 0, 0, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chests Section
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 10, bottom: 8.0),
              child: Text(
                'Global Items',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: globalItems.length,
              itemBuilder: (context, index) {
                return GlobalItemRow(
                  itemName: globalItems[index]['name'],
                  itemPrice: globalItems[index]['price'],
                  itemRarity: globalItems[index]['rarity'],
                );
              },
            ),
          ],
        ),
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
