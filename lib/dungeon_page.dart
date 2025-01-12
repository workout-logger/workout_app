import 'dart:async';
import 'package:flutter/material.dart';
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

  /// Whether the player has chosen a dungeon or not.
  /// If `null`, show the dungeon selection screen.
  /// If a dungeon index is chosen, show the main dungeon UI.
  int? _selectedDungeonIndex;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final dungeonMgr = DungeonManager();

    // 1) Check from the server if the dungeon is running
    //    (This requires a method like checkDungeonRunningStatus() 
    //    or is_player_in_dungeon() in DungeonManager).

    // If not loaded, request actual data from the server
    if (!dungeonMgr.isLoaded) {
      dungeonMgr.requestDungeonData();
    }

    // Listen for data updates
    dungeonMgr.setDungeonUpdateCallback((data) {
      if (mounted) {
        setState(() {
          if (_isRefreshing) {
            _isRefreshing = false;
          }
        });
      }
    });

    // Setup animations
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

    // Trigger the animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }


  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refreshDungeon() async {
    setState(() {
      _isRefreshing = true;
    });
    // Actually fetch from server
    await DungeonManager().requestDungeonData(showLoadingOverlay: false);
    while (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Builds the dungeon selection screen (3 images).
  Widget _buildDungeonSelectionScreen() {
    // Example dungeon data
    final dungeons = [
      {
        'name': 'Crypt of Shadows',
        'image': 'assets/images/dungeon1.png',
      },
      {
        'name': 'Dragon’s Lair',
        'image': 'assets/images/dungeon2.png',
      },
      {
        'name': 'Arcane Catacombs',
        'image': 'assets/images/dungeon3.png',
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
                    onTap: () {
                      setState(() {
                        _selectedDungeonIndex = index;
                      });
                      DungeonManager().startDungeon();
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
                            child: Text(
                              dungeon['name'] ?? 'Unknown Dungeon',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
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

  @override
  Widget build(BuildContext context) {
    final manager = DungeonManager();

    final isLoading = manager.isLoading; // Show a loading overlay
    final dungeonItems = manager.dungeonItems; // Items from server
    final dialogue = manager.dungeonDialogue; // NPC/event text
    final dialogueOptions = manager.dialogueOptions; // Options from server
    final isRunning = manager.isDungeonRunning; // Are we in a dungeon?

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
                // If _selectedDungeonIndex is null => show selection, else main UI
                child: isRunning == false
                    ? _buildDungeonSelectionScreen()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // 1) Character + items side by side
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 16.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Character + stats
                                  Expanded(
                                    flex: 1,
                                    child: CharacterStatsView(
                                      head: InventoryManager()
                                              .equippedItems['heads'] ??
                                          '',
                                      armour: InventoryManager()
                                              .equippedItems['armour'] ??
                                          '',
                                      legs: InventoryManager()
                                              .equippedItems['legs'] ??
                                          '',
                                      melee: InventoryManager()
                                              .equippedItems['melee'] ??
                                          '',
                                      shield: InventoryManager()
                                              .equippedItems['shield'] ??
                                          '',
                                      wings: InventoryManager()
                                              .equippedItems['wings'] ??
                                          '',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Collected items to the RIGHT of the character
                                  Expanded(
                                    flex: 1,
                                    child: dungeonItems.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                              "No items found in the dungeon",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : _buildItemRow(dungeonItems),
                                  ),
                                ],
                              ),
                            ),
                            // 2) Dialogue + choices
                            _buildDialogueSection(dialogue, dialogueOptions),
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

          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the horizontal item list.
  Widget _buildItemRow(List<Map<String, dynamic>> items) {
    return Expanded(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];

          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.blueGrey[800],
              // No fixed width/height here—let it expand
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
    );

  }


  /// Builds the dialogue section with clickable NPC image and option buttons.
  Widget _buildDialogueSection(String mainDialogue, List<String> options) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.4),
            offset: const Offset(0, 3),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable NPC image
          InkWell(
            onTap: () {
              // Show a short description of the character
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Mysterious Figure"),
                  content: const Text(
                    "A wandering spirit with secrets to share. "
                    "No one knows their true past... or intentions.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("Close"),
                    )
                  ],
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                color: Colors.grey[800],
                width: 60,
                height: 60,
                child: Image.asset(
                  'assets/images/other_character.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Dialogue + Options
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainDialogue.isNotEmpty
                      ? mainDialogue
                      : "The dungeon is eerily silent...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                if (options.isNotEmpty)
                  Column(
                    children: options.map((opt) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 8),
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            // Send choice to server
                            final index = options.indexOf(opt);
                            DungeonManager().makeChoice(index);
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
                    "No options available...",
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Exit Dungeon button at the bottom
  Widget _buildExitButton(bool isRunning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple[700],
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
        child: const Text("Exit Dungeon"),
      ),
    );
  }
}
