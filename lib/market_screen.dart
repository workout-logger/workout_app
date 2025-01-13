import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/constants.dart';
import 'package:provider/provider.dart';
import 'package:workout_logger/currency_provider.dart'; // Ensure you have provider package added

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
        backgroundColor: Colors.black87, // Dark background
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
              buyItem(listingId); // Proceed with the purchase
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
        return Colors.deepPurple.shade300;
      case 'Legendary':
        return Colors.amber.shade300;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color here
      // Remove AppBar since currency display will be in the body
      body: Container(
        color: Colors.black, // Consistent background
        child: Column(
          children: [
            // Currency Display at the Top (matches ChestsScreen layout)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Align row to the left
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.yellow,
                          size: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currencyProvider.currency.toStringAsFixed(0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Expanded to take the remaining space for the list
            Expanded(
              child: Container(
                color: Colors.black, // Consistent background
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: marketItems.length,
                        itemBuilder: (context, index) {
                          final item = marketItems[index];
                          final rarityColor = _getRarityColor(item['rarity']);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
