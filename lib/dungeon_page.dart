// lib/dungeon_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'package:provider/provider.dart';
import 'package:workout_logger/currency_provider.dart';
import 'package:workout_logger/inventory/inventory_manager.dart';
import 'package:workout_logger/inventory/item_card.dart';
import '../ui_view/character_stats_dungeon.dart';
import 'dungeon_manager.dart';

class DungeonPage extends StatefulWidget {
  const DungeonPage({Key? key}) : super(key: key);

  @override
  State<DungeonPage> createState() => _DungeonPageState();
}

class _DungeonPageState extends State<DungeonPage> with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  int? _selectedDungeonIndex;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();

    final dungeonMgr = DungeonManager();

    if (!dungeonMgr.isLoaded) {
      dungeonMgr.requestDungeonData();
    }

    dungeonMgr.setDungeonUpdateCallback((data) {
      if (mounted) {
        setState(() {
          if (_isRefreshing) {
            _isRefreshing = false;
          }
          if (data != null && data['type'] == 'logs_updated') {
            // Optionally, perform actions based on new logs
          }
        });
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
    // Start auto-refresh timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _animController.dispose();
    _stopAutoRefresh(); // Stop the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _refreshDungeon() async {
    setState(() {
      _isRefreshing = true;
    });
    await DungeonManager().requestDungeonData(showLoadingOverlay: false);
    setState(() {
      _isRefreshing = false;
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _refreshDungeon();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }
  
  /// Formats the timestamp into a readable string
  String _formatTimestamp(String timestamp) {
    try {
      DateTime parsedDate = DateTime.parse(timestamp).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
    } catch (e) {
      return timestamp; // Return the original if parsing fails
    }
  }

  /// Builds the dungeon selection screen (3 images).
  Widget _buildDungeonSelectionScreen() {
    final dungeons = [
      {
        'name': 'Shadowed Crypt',
        'image': 'assets/images/dungeon1.png',
        'difficulty': 'Easy'
      },
      {
        'name': 'Dragon\'s Lair', 
        'image': 'assets/images/dungeon2.png',
        'difficulty': 'Medium'
      },
      {
        'name': 'Arcane Catacombs',
        'image': 'assets/images/dungeon3.png',
        'difficulty': 'Hard'
      },
    ];

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Choose Your Dungeon",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Display 3 dungeon options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(dungeons.length, (index) {
                  final dungeon = dungeons[index];
                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedDungeonIndex = index;
                      });
                      DungeonManager().startDungeon();
                      await _refreshDungeon();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: Image.asset(
                              dungeon['image']!,
                              width: 120,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => Container(
                                color: Colors.black45,
                                width: 120,
                                height: 80,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dungeon['name'] ?? 'Unknown Dungeon',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Difficulty: ${dungeon['difficulty']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays logs to the right of the character with timestamps
  Widget _buildLogSection(List<Map<String, dynamic>> dungeonLogs) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Darker background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  "Dungeon Log",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF3D3D3D), height: 1),
          Expanded(
            child: ListView.builder(
              reverse: true,
              physics: const BouncingScrollPhysics(),
              itemCount: dungeonLogs.length,
              itemBuilder: (context, index) {
                final log = dungeonLogs[dungeonLogs.length - 1 - index];
                final message = log['message'] ?? 'No message';
                final timestamp = log['timestamp'] ?? '';
                final formattedTime = _formatTimestamp(timestamp);

                Color messageColor = Colors.white70;
                IconData icon = Icons.info_outline;
                if (message.contains('damage')) {
                  messageColor = Colors.redAccent;
                  icon = Icons.warning_amber_rounded;
                } else if (message.contains('Collected item') || message.contains('regained')) {
                  messageColor = Colors.greenAccent;
                  icon = Icons.add_circle_outline;
                } else if (message.contains('Encountered NPC')) {
                  messageColor = Colors.orangeAccent;
                  icon = Icons.person_outline;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      message,
                      style: TextStyle(
                        color: messageColor,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    subtitle: Text(
                      formattedTime,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildCharacterAndLogs(List<Map<String, dynamic>> logs) {
  final currentHealth = DungeonManager().currentHealth;
  final maxHealth = 100;
  final healthPercentage = currentHealth / maxHealth;

  return Column(
    mainAxisSize: MainAxisSize.min, // Prevent expansion to infinite height
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CharacterStatsView(
              head: InventoryManager().equippedItems['heads'] ?? '',
              armour: InventoryManager().equippedItems['armour'] ?? '',
              legs: InventoryManager().equippedItems['legs'] ?? '',
              melee: InventoryManager().equippedItems['melee'] ?? '',
              shield: InventoryManager().equippedItems['shield'] ?? '',
              wings: InventoryManager().equippedItems['wings'] ?? '',
            ),
          ),
          const SizedBox(width: 2),
          Flexible(
            fit: FlexFit.loose, // Allows flexible sizing within the available height
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300), // Set max height
              child: _buildLogSection(logs),
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Health: $currentHealth / $maxHealth",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: healthPercentage.clamp(0.0, 1.0),
                backgroundColor: Colors.red.shade900,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.redAccent,
                ),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}



  /// Builds the "Found Items" section on a new line
  Widget _buildFoundItemsSection(List<Map<String, dynamic>> dungeonItems) {
    if (dungeonItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 30, top: 16, right: 16, bottom: 16),
        child: Text(
          "No items found in the dungeon yet",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            "Found Items",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Horizontal list
        Padding(
          padding: const EdgeInsets.only(left: 26.0),
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dungeonItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = dungeonItems[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: Colors.blueGrey[800],
                    width: 130,
                    child: InventoryItemCard(
                      itemName: item['name'] ?? "Unknown",
                      category: item['category'] ?? "none",
                      fileName: item['file_name'] ?? "placeholder",
                      isEquipped: item['is_equipped'] ?? false,
                      onEquipUnequip: () {},
                      rarity: item['rarity'] ?? "common",
                      outOfChest: false,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDialoguePopup(String mainDialogue, List<String> options) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54, // dims the background
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 300, // Limit the width of the popup
                maxHeight: MediaQuery.of(context).size.height * 0.8, // Occupy up to 80% of screen height
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title + main dialogue text
                    Text(
                      "Mysterious Figure",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mainDialogue,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Options
                    if (options.isNotEmpty)
                      Column(
                        children: options.map((opt) {
                          final index = options.indexOf(opt);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple[700],
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              ),
                              onPressed: () {
                                // Send choice to server
                                DungeonManager().makeChoice(index);

                                // Optionally hide the popup after choosing
                                final mgr = DungeonManager();
                                mgr.dungeonDialogue = "";
                                mgr.dialogueOptions = [];
                              },
                              child: Text(
                                opt,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Text(
                        "(No options available...)",
                        style: TextStyle(color: Colors.white54),
                      ),

                    // Close or dismiss button
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        // Manually clear the dialogue so the popup disappears
                        final mgr = DungeonManager();
                        mgr.dungeonDialogue = "";
                        mgr.dialogueOptions = [];
                        Provider.of<CurrencyProvider>(context, listen: false).refreshCurrencyFromBackend();
                        await _refreshDungeon();
                        // Force UI update
                        setState(() {});
                      },
                      child: const Text(
                        "Dismiss", 
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildExitButton(bool isRunning) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: () {
            // Stop dungeon logic
            if (isRunning) {
              DungeonManager().stopDungeon();
            }
            // Return to dungeon selection 
            setState(() {
              _selectedDungeonIndex = null;
            });
          },
          child: const Text(
            "Exit Dungeon and Collect Items",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = DungeonManager();

    final isLoading = manager.isLoading;           
    final dungeonItems = manager.dungeonItems;    
    final dialogue = manager.dungeonDialogue;     
    final dialogueOptions = manager.dialogueOptions;
    final isRunning = manager.isDungeonRunning;   
    final dungeonLogs = manager.dungeonLogs;      

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.black,
        title: const Text(
          "Dungeons",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshDungeon,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                // If no dungeon is running => show selection, else show main UI
                child: (!isRunning)
                    ? _buildDungeonSelectionScreen()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1) Character + Logs row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 16.0,
                              ),
                              child: _buildCharacterAndLogs(dungeonLogs),
                            ),

                            // 2) Found Items (title + list) on new line
                            _buildFoundItemsSection(dungeonItems),

                            // 3) Exit dungeon button at the bottom
                            const SizedBox(height: 30),
                            _buildExitButton(isRunning),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),

          // If we have dialogue, show it as a center popup
          if (dialogue.isNotEmpty)
            _buildDialoguePopup(dialogue, dialogueOptions),
        ],
      ),
    );
  }
}
