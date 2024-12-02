import 'package:flutter/material.dart';
import 'websocket_manager.dart';
import 'inventory_manager.dart'; // Import the InventoryManager

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  void initState() {
    super.initState();

    // Register callback for inventory updates
    WebSocketManager().setInventoryUpdateCallback((updatedItems) {
      InventoryManager().updateInventory(updatedItems);
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryItems = InventoryManager().inventoryItems;

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
          // Inventory Display
          Expanded(
            child: inventoryItems.isEmpty
                ? const Center(
                    child: Text(
                      "No items in inventory",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: inventoryItems.length,
                    itemBuilder: (context, index) {
                      final item = inventoryItems[index];
                      return InventoryItemCard(
                        itemName: item['name'],
                        category: item['category'],
                        fileName: item['file_name'],
                      );
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
  final String category;
  final String fileName;

  const InventoryItemCard({
    super.key,
    required this.itemName,
    required this.category,
    required this.fileName,
  });

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
          Image.asset(
            'assets/character/$category/$fileName',
            height: 80,
            width: 80,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                color: Colors.redAccent,
                size: 40,
              );
            },
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
