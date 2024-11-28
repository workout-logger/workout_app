import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  Future<List<Map<String, dynamic>>> fetchInventory() async {
    final response = await http.get(Uri.parse('https://api.example.com/inventory')); // Replace with your API endpoint
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load inventory');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chest details
    final List<Map<String, dynamic>> chests = [
      {'name': 'Common', 'price': 100},
      {'name': 'Rare', 'price': 500},
      {'name': 'Epic', 'price': 1000},
      {'name': 'Legendary', 'price': 3000},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(
            left: 4,
            right: 16,
            top: 60,
            bottom: 30,
          ),
          child: Text(
            "Inventory and Cases",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: 1.2,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available Chests Section Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: const Text(
              "Available Chests",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Horizontal Scroll for Chests
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: chests.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChestCard(
                    chestName: chests[index]['name'],
                    chestPrice: chests[index]['price'],
                    chestNumber: index,
                  ),
                );
              },
            ),
          ),
          // Inventory Section Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: const Text(
              "Inventory",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Inventory Display using FutureBuilder
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchInventory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Failed to load inventory", style: TextStyle(color: Colors.red)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No items in inventory", style: TextStyle(color: Colors.white)));
                } else {
                  final inventoryItems = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: inventoryItems.length,
                    itemBuilder: (context, index) {
                      final item = inventoryItems[index];
                      return InventoryItemCard(itemName: item['name']);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
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
      color: Colors.grey[850],
      child: InkWell(
        onTap: () {
          // Handle chest purchase
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Image.asset(
                'assets/images/Pixel_Chest_Pack/chest_$chestNumber.png',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chestName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              "$chestPrice Coins",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryItemCard extends StatelessWidget {
  final String itemName;

  const InventoryItemCard({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star, // Replace with item icon if available
            color: Colors.amberAccent,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            itemName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
