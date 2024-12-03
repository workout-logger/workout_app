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
    // final List<Map<String, dynamic>> chests = [
    //   {'name': 'Common', 'price': 100},
    //   {'name': 'Rare', 'price': 500},
    //   {'name': 'Epic', 'price': 1000},
    //   {'name': 'Legendary', 'price': 3000},
    // ];

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
            "Inventory",
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
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          //   child: const Text(
          //     "Available Chests",
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 20,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
          // // Horizontal Scroll for Chests
          // SizedBox(
          //   height: 200,
          //   child: ListView.builder(
          //     scrollDirection: Axis.horizontal,
          //     itemCount: chests.length,
          //     itemBuilder: (context, index) {
          //       return Padding(
          //         padding: const EdgeInsets.symmetric(horizontal: 8),
          //         child: ChestCard(
          //           chestName: chests[index]['name'],
          //           chestPrice: chests[index]['price'],
          //           chestNumber: index,
          //         ),
          //       );
          //     },
          //   ),
          // ),
          // Inventory Section Title
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          //   child: const Text(
          //     "Inventory",
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 20,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
          // Inventory Display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => InventoryActionsDrawer(
            itemName: itemName,
            category: category,
            fileName: fileName,
          ),
        );
      },
      child: Card(
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
      ),
    );
  }
}
class InventoryActionsDrawer extends StatelessWidget {
  final String itemName;
  final String category;
  final String fileName;

  const InventoryActionsDrawer({
    super.key,
    required this.itemName,
    required this.category,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final isEquipped = InventoryManager().isEquipped(itemName);

    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 22, 19, 19),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle for better UX
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          // Item Display
          Row(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEquipped ? "Currently equipped" : "Not equipped",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ActionButton(
                icon: Icons.remove_red_eye,
                label: "View Details",
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("View details feature is coming soon!"),
                    ),
                  );
                },
              ),
              ActionButton(
                icon: Icons.attach_money,
                label: "Sell",
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Selling feature coming soon!"),
                    ),
                  );
                },
              ),
              ActionButton(
                icon: isEquipped ? Icons.close : Icons.check,
                label: isEquipped ? "Unequip" : "Equip",
                onTap: () {
                  InventoryManager().equipItem(itemName);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEquipped ? "$itemName unequipped!" : "$itemName equipped!",
                      ),
                    ),
                  );
                },
              ),
              ActionButton(
                icon: Icons.upgrade,
                label: "Upgrade",
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Upgrade feature is coming soon!"),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[700],
            radius: 30,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
