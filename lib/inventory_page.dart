import 'package:flutter/material.dart';
import 'package:workout_logger/item_card.dart';
import 'websocket_manager.dart';
import 'inventory_manager.dart'; // Import the InventoryManager
import 'ui_view/character_stats_inv.dart';
import 'lottie_segment_player.dart'; // Import the LottieSegmentPlayer widget
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _isRefreshing = false;
  // Remove _isLoading variable

  void _refreshUI() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Check if data is already loaded
    if (!InventoryManager().isLoading) {
      // Data is already loaded, no need to set up the WebSocket callback again
      return;
    }

    // Register callback for inventory updates
    WebSocketManager().setInventoryUpdateCallback((updatedItems) {
      InventoryManager().updateInventory(updatedItems);
      if (mounted) {
        setState(() {});
      }
      // If we're refreshing, stop the refresh indicator
      if (_isRefreshing) {
        _isRefreshing = false;
      }
    });

    // Request the initial inventory data if loading
    InventoryManager().requestInventoryUpdate();
  }

 Future<void> _refreshInventory() async {
    setState(() {
      _isRefreshing = true;
    });

    // Request the latest inventory data without showing the loading overlay
    InventoryManager().requestInventoryUpdate(showLoadingOverlay: false);

    // Wait until the inventory is updated via the callback
    while (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryItems = InventoryManager().inventoryItems;
    final equippedItems = InventoryManager().equippedItems;
    final isLoading = InventoryManager().isLoading; // Use the shared loading state

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
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: _refreshInventory,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Any other widgets you might have
                CharacterStatsView(
                  head: equippedItems['heads'] ?? '',
                  armour: equippedItems['armour'] ?? '',
                  legs: equippedItems['legs'] ?? '',
                  melee: equippedItems['melee'] ?? '',
                  shield: equippedItems['shield'] ?? '',
                  wings: equippedItems['wings'] ?? '',
                ),
                // Inventory Display
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: inventoryItems.isEmpty
                        ? const Center(
                            child: Text(
                              "No items in inventory",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.65, // allow more vertical space
                          ),
                          itemCount: inventoryItems.length,
                          itemBuilder: (context, index) {
                            final item = inventoryItems[index];
                            // No Flexible here:
                            return InventoryItemCard(
                              itemName: item['name'],
                              category: item['category'],
                              fileName: item['file_name'],
                              isEquipped: item['is_equipped'],
                              onEquipUnequip: _refreshUI,
                              rarity: item['rarity'],
                            );
                          },
                        )
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: LottieSegmentPlayer(
                    animationPath: 'assets/animations/loading.json',
                    endFraction: 0.7,
                    width: 150, // Increase the width here
                    height: 150, // Increase the height here
                  ),
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





class InventoryActionsDrawer extends StatelessWidget {
  final String itemName;
  final String category;
  final String fileName;
  final bool isEquipped;
  final VoidCallback onEquipUnequip;



  const InventoryActionsDrawer({
    super.key,
    required this.itemName,
    required this.category,
    required this.fileName,
    required this.isEquipped,
    required this.onEquipUnequip,

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
                'assets/character/$category/$fileName.png',
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
                  InventoryManager().equipItem(itemName, fileName, category);
                  Navigator.of(context).pop();
                  onEquipUnequip();
                  final isNowEquipped = InventoryManager().isEquipped(itemName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isNowEquipped ? "$itemName equipped!" : "$itemName unequipped!",
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
