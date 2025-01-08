// lib/inventory/inventory_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/constants.dart';
import 'package:workout_logger/inventory/item_card.dart';
import '../websocket_manager.dart';
import 'inventory_manager.dart'; // Import the InventoryManager
import '../ui_view/character_stats_inv.dart';
import '../lottie_segment_player.dart'; // Import the LottieSegmentPlayer widget
import 'package:http/http.dart' as http;
import '../currency_provider.dart'; // Import CurrencyProvider

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _isRefreshing = false;

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
    final equippedItems = InventoryManager().inventoryItems.where((item) => item['is_equipped']).toList();
    final otherItems = InventoryManager().inventoryItems.where((item) => !item['is_equipped']).toList();
    final isLoading = InventoryManager().isLoading;
    final stats = (InventoryManager().stats ?? {}).map((key, value) {
      return MapEntry(key, int.tryParse(value.toString()) ?? 0); // Convert to int or default to 0
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(
            left: 4,
            right: 16,
            top: 60,
            bottom: 30,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Inventory",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: 1.2,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, child) {
                  return Row(
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
                  );
                },
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshInventory,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Character stats
                  CharacterStatsView(
                    head: InventoryManager().equippedItems['heads'] ?? '',
                    armour: InventoryManager().equippedItems['armour'] ?? '',
                    legs: InventoryManager().equippedItems['legs'] ?? '',
                    melee: InventoryManager().equippedItems['melee'] ?? '',
                    shield: InventoryManager().equippedItems['shield'] ?? '',
                    wings: InventoryManager().equippedItems['wings'] ?? '',
                    stats: stats,
                  ),

                  // Equipped Items Section
                  if (equippedItems.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0, left: 10.0),  
                        child: const Text(
                          "Equipped Items",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    _buildScrollableGrid(equippedItems),
                  ],

                  // Other Items Section
                  if (otherItems.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30.0, bottom: 20.0, left: 10.0),  
                        child: const Text(
                          "Other Items",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    _buildScrollableGrid(otherItems),
                  ],
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: LottieSegmentPlayer(
                    animationPath: 'assets/animations/sword.json',
                    endFraction: 1,
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a scrollable grid for equipped or other items.
  Widget _buildScrollableGrid(List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double spacing = 10.0;
          const int columns = 3;
          final double totalSpacing = (columns - 1) * spacing;
          final double baseWidth = (constraints.maxWidth - totalSpacing) / columns;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this grid
            shrinkWrap: true, // Allow the grid to wrap its content
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1 / 1.5, // Adjust based on your card design
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InventoryItemCard(
                itemName: item['name'],
                category: item['category'],
                fileName: item['file_name'],
                isEquipped: item['is_equipped'],
                onEquipUnequip: _refreshUI,
                rarity: item['rarity'],
              );
            },
          );
        },
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
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SellItemDialog(itemName: itemName);
                    },
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
                        isNowEquipped
                            ? "$itemName equipped!"
                            : "$itemName unequipped!",
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

class SellItemDialog extends StatefulWidget {
  final String itemName;

  const SellItemDialog({Key? key, required this.itemName}) : super(key: key);

  @override
  _SellItemDialogState createState() => _SellItemDialogState();
}

class _SellItemDialogState extends State<SellItemDialog> {
  double _price = 50.0; // Default price
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priceController.text =
        _price.toStringAsFixed(0); // Initialize text box with slider value
  }

  void _submitListing() async {
    final price = double.tryParse(_priceController.text.trim());

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price!')),
      );
      return;
    }

    try {
      // Replace with your API endpoint
      final String apiUrl = APIConstants.sellMarket;

      // Prepare the request payload
      final payload = {
        'item_name': widget.itemName,
        'price': _priceController.text.trim(),
      };
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('authToken');

      // Send POST request to backend
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode(payload),
      );

      // Parse the response
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        Navigator.of(context).pop(); // Close the dialog
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item "${widget.itemName}" listed successfully!'),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to list item.');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: Text(
        'Sell ${widget.itemName}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Price', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _price,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  activeColor: Colors.yellow,
                  inactiveColor: Colors.grey,
                  onChanged: (value) {
                    setState(() {
                      _price = value;
                      _priceController.text = _price.toStringAsFixed(0);
                    });
                  },
                ),
              ),
            ],
          ),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Price',
              labelStyle: const TextStyle(color: Colors.yellow),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.yellow),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.yellow, width: 2),
              ),
            ),
            onChanged: (value) {
              final parsedValue = double.tryParse(value);
              if (parsedValue != null && parsedValue >= 0 && parsedValue <= 1000) {
                setState(() {
                  _price = parsedValue;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.yellow)),
        ),
        ElevatedButton(
          onPressed: _submitListing,
          style: ElevatedButton.styleFrom(),
          child: const Text('Submit', style: TextStyle(color: Colors.black)),
        ),
      ],
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
