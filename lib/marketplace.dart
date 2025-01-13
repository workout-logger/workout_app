import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/chest/chests.dart';
import 'package:workout_logger/constants.dart';
import 'package:workout_logger/market_screen.dart';
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
        body: FutureBuilder<String>(
          future: SharedPreferences.getInstance().then((prefs) => prefs.getString('authToken') ?? ''),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final token = snapshot.data!;
              return TabBarView(
                children: [
                  MarketScreen(),
                  ChestsScreen(), // New Chests Tab
                  ChatPage(
                    websocketUrl: '${APIConstants.socketUrl}/ws/chat/?token=$token',
                    token:token,
                  ),
                  FriendsScreen(),
                ],
              );
            }
            return Center(child: CircularProgressIndicator());
          }
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
