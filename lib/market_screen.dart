import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/constants.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<Map<String, dynamic>> marketItems = [];
  bool isLoading = true;

  Future<void> fetchMarketItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      final response = await http.get(
        Uri.parse(APIConstants.showListings),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          marketItems = List<Map<String, dynamic>>.from(data['listings']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch market items')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> buyItem(int listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      final response = await http.post(
        Uri.parse(APIConstants.buyMarket),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'listing_id': listingId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        fetchMarketItems(); // Refresh market items
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void confirmPurchase(
    BuildContext context,
    int listingId,
    String itemName,
    int price,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,  // Dark background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: Text(
          "Confirm Purchase",
          style: TextStyle(color: Colors.yellow),
        ),
        content: Text(
          "Do you want to buy $itemName for $price Coins?",
          style: TextStyle(color: Colors.yellow),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.yellow),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              buyItem(listingId);         // Proceed with the purchase
            },
            child: Text(
              "Buy",
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    fetchMarketItems();
  }

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
      color: const Color.fromARGB(255, 0, 0, 0),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: marketItems.length,
              itemBuilder: (context, index) {
                final item = marketItems[index];
                final rarityColor = _getRarityColor(item['rarity']);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Card(
                    elevation: 2,
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        final int price;
                        try {
                          price = double.parse(item['price']).toInt();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid price format')),
                          );
                          return;
                        }

                        confirmPurchase(
                          context,
                          item['id'],
                          item['itemName'],
                          price,
                        );
                      },

                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              child: item['fileName'] != null
                                  ? Image.asset(
                                      '${item['fileName']}.png',                                      
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                    )
                                  : const SizedBox(
                                      height: 64,
                                      width: 64,
                                      child: Icon(Icons.image_outlined,
                                          size: 24, color: Colors.white24),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['itemName'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    item['rarity'],
                                    style: TextStyle(
                                        color: rarityColor.withOpacity(0.7),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${item['price']} Coins",
                              style: const TextStyle(
                                  color: Colors.greenAccent, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
