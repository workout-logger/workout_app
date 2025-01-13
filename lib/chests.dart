// lib/chests.dart

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/currency_provider.dart';
import 'package:workout_logger/flying_card.dart';
import 'package:workout_logger/inventory/item_card.dart';
import 'package:workout_logger/inventory/inventory_manager.dart';
import 'package:workout_logger/websocket_manager.dart';
import 'animated_chest.dart';
import 'package:workout_logger/constants.dart';
import 'package:http/http.dart' as http;

class ChestsScreen extends StatefulWidget {
  ChestsScreen({Key? key}) : super(key: key);

  @override
  _ChestsScreenState createState() => _ChestsScreenState();
}

class _ChestsScreenState extends State<ChestsScreen> {
  final List<Map<String, dynamic>> chestData = [
    {'name': 'Common Chest', 'price': 100, 'number': 1},
    {'name': 'Rare Chest', 'price': 500, 'number': 2},
    {'name': 'Epic Chest', 'price': 1000, 'number': 3},
  ];

  OverlayEntry? _overlayEntry;
  final List<GlobalKey> _chestKeys = [];

  @override
  void initState() {
    super.initState();
    // Initialize a GlobalKey for each chest
    _chestKeys.addAll(List.generate(chestData.length, (_) => GlobalKey()));
  }
  
  void _onChestTap(int index) async {
    final chest = chestData[index];
    final chestKey = _chestKeys[index];

    // Access the current currency from the provider
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final double chestCost = chest['price'].toDouble();

    if (currencyProvider.currency < chestCost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough currency to open the ${chest['name']}!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Deduct chest cost from currency
    currencyProvider.updateCurrency(currencyProvider.currency - chestCost);

    // Proceed with opening the chest
    AnimatedChest.setHasAnimated(false);

    final RenderBox? box = chestKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final Offset position = box.localToGlobal(Offset.zero);
    final Size chestSize = box.size;
    final Size size = MediaQuery.of(context).size;

    // Remove existing overlay
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => _ChestOverlay(
        // Adjust position to center of the chest card
        initialX: position.dx + (chestSize.width - 120) / 2,  // 100 is the initial chest width
        initialY: position.dy + (chestSize.height - 151) / 2, // 100 is the initial chest height
        screenWidth: size.width,
        screenHeight: size.height,
        onClose: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        chestNumber: chest['number'],
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 16.0,
              ),
              itemCount: chestData.length,
              itemBuilder: (context, index) {
                final chest = chestData[index];
                return ChestCard(
                  key: _chestKeys[index],
                  chestName: chest['name'],
                  chestPrice: chest['price'], 
                  chestNumber: chest['number'],
                  onChestTap: () => _onChestTap(index),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// _ChestOverlay Widget

class _ChestOverlay extends StatefulWidget {
  final double initialX;
  final double initialY;
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onClose;
  final int chestNumber; // New parameter

  const _ChestOverlay({
    required this.initialX,
    required this.initialY,
    required this.screenWidth,
    required this.screenHeight,
    required this.onClose,
    required this.chestNumber, // Initialize it correctly
  });

  @override
  _ChestOverlayState createState() => _ChestOverlayState();
}

class _ChestOverlayState extends State<_ChestOverlay> {
  bool _centered = false;
  bool _opened = false;
  bool _cardsDealt = false;
  int _currentCardIndex = -1;
  bool _showingStats = false;
  bool _animating = true;
  final List<Map<String, dynamic>> _dealtCards = [];
  bool _collecting = false;
  List<Map<String, dynamic>> _collectingCards = [];

  final double _cardWidth = 120.0;
  final double _cardHeight = 150.0;
  bool _currentCardAnimationComplete = true;
  Map<String, dynamic>? _currentlyFlyingCard;

  final List<Map<String, dynamic>> _inventoryItems = [];

  late final double _centerDisplayX;
  final double _statsOffset = 200.0;

  Future<List<dynamic>?> _buyChest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String apiUrl = APIConstants.buyChest;
    final String? authToken = prefs.getString('authToken');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: json.encode({
          'chest_id': widget.chestNumber.toString(),
        }),
      );

      if (!mounted) return null;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        final int currency = data['currency'];

        // Manually extract non-zero stats for each item
        List<Map<String, dynamic>> processedItems = items.map((item) {
          Map<String, dynamic> processedItem = {
            'id': item['id'] ?? 0,
            'itemName': item['itemName'] ?? 'Unknown',
            'category': item['category'] ?? 'Unknown',
            'fileName': item['fileName'] ?? '',
            'isEquipped': false,
            'rarity': item['rarity'] ?? 'common',
          };

          // Extract stats only if they are greater than zero
          List<String> statFields = [
            'strength',
            'agility',
            'intelligence',
            'stealth',
            'speed',
            'defence',
          ];

          Map<String, dynamic> stats = {};
          for (var stat in statFields) {
            if (item.containsKey(stat) && (item[stat] ?? 0) > 0) {
              stats[stat] = item[stat];
            }
          }

          if (stats.isNotEmpty) {
            processedItem['stats'] = stats;
          }

          return processedItem;
        }).toList();

        // Update state and trigger animation sequence
        setState(() {
          _inventoryItems.clear(); // Clear existing items first
          _inventoryItems.addAll(processedItems);
        
          // Reset animation state
          _currentCardIndex = -1;
          _currentCardAnimationComplete = true;
          _cardsDealt = false;
          _showingStats = false;
          _animating = true;
        });

        // Update currency
        InventoryManager().requestInventoryUpdate();
        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
        currencyProvider.updateCurrency(currency.toDouble());

        // Debug logging
        
        return items;
      } else {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to purchase chest: ${json.decode(response.body)['message']}')),
        );
        return null;
      }
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _centerDisplayX = widget.screenWidth / 2 - (_cardWidth / 2) - (_statsOffset / 2);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Await the chest purchase and item fetch
      await _buyChest();


      // Start the chest animation after items are fetched
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _centered = true;
          });
        }
      });
    });
  }

  void _collectCards() {
    if (_dealtCards.isEmpty || _collecting) return;

    setState(() {
      _collecting = true;
      _collectingCards = List.from(_dealtCards);
      _dealtCards.clear();
    });

    // After animation completes, close the overlay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  void _startNextCardAnimation() {
    if (_currentCardIndex < _inventoryItems.length - 1 && _currentCardAnimationComplete) {
      setState(() {
        _currentCardIndex++;
        if (_currentCardIndex < _inventoryItems.length) {
          _currentlyFlyingCard = _inventoryItems[_currentCardIndex];
        } else {
          _currentlyFlyingCard = null;
        }
        _currentCardAnimationComplete = false;
        _showingStats = false;
      });
    } else {
    }
  }
  
  void _onCardAnimationComplete() {
    if (_currentlyFlyingCard != null) {
      setState(() {
        _dealtCards.add(_currentlyFlyingCard!);
        _currentlyFlyingCard = null;
        _currentCardAnimationComplete = true;
      });
      // Trigger next animation only if there are more cards
      if (_currentCardIndex < _inventoryItems.length - 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _startNextCardAnimation();
          }
        });
      } else {
        setState(() {
          _animating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none, // Allow flying cards to go outside the stack bounds
        fit: StackFit.expand,
        children: [
          // Background overlay
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _centered ? 0.7 : 0.0,
            child: GestureDetector(
              onTap: () {
                // Optionally allow closing if needed
              },
              child: Container(color: Colors.black),
            ),
          ),
          // Gesture to skip current card animation
          if (_currentlyFlyingCard != null)
            GestureDetector(
              onTapDown: (_) => _skipCurrentCardAnimation(),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          // Dealt cards in deck
          ..._dealtCards.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Positioned(
              left: _getFinalXPosition(index),
              top: _getFinalYPosition(index),
              width: _cardWidth,
              height: _cardHeight,
              child: Transform.scale(
                scale: 0.8,
                child: InventoryItemCard(
                  rarity: item['rarity'],
                  itemName: item['itemName'],
                  category: item['category'],
                  fileName: item['fileName'],
                  isEquipped: item['isEquipped'],
                  onEquipUnequip: () {},
                ),
              ),
            );
          }).toList(),
          // Collecting animation
          if (_collecting)
            ..._collectingCards.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 500 + (index * 100)),
                curve: Curves.easeInBack,
                tween: Tween(
                  begin: Offset(
                    _getFinalXPosition(index),
                    _getFinalYPosition(index),
                  ),
                  end: Offset(
                    widget.screenWidth / 2 - (_cardWidth / 2), // Center horizontally
                    widget.screenHeight + 50, // Below screen bottom
                  ),
                ),
                builder: (context, Offset offset, child) {
                  return Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    width: _cardWidth,
                    height: _cardHeight,
                    child: Transform.scale(
                      scale: 0.8,
                      child: InventoryItemCard(
                        rarity: item['rarity'],
                        itemName: item['itemName'],
                        category: item['category'],
                        fileName: item['fileName'],
                        isEquipped: item['isEquipped'],
                        onEquipUnequip: () {},
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          // Regular dealt cards (when not collecting)
          if (!_collecting)
            ..._dealtCards.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Positioned(
                left: _getFinalXPosition(index),
                top: _getFinalYPosition(index),
                width: _cardWidth,
                height: _cardHeight,
                child: Transform.scale(
                  scale: 0.8,
                  child: InventoryItemCard(
                    rarity: item['rarity'],
                    itemName: item['itemName'],
                    category: item['category'],
                    fileName: item['fileName'],
                    isEquipped: item['isEquipped'],
                    onEquipUnequip: () {},
                  ),
                ),
              );
            }).toList(),
          // Chest Animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            left: _centered ? widget.screenWidth / 2 - 100.0 : widget.initialX,
            top: _centered ? widget.screenHeight / 2 - 200.0 : widget.initialY,
            width: _centered ? 200.0 : 120.0,
            height: _centered ? 200.0 : 90.0,
            onEnd: () {
              if (_centered && !_opened) {
                setState(() {
                  _opened = true;
                });
              }
            },
            child: AnimatedChest(
              chestNumber: widget.chestNumber, // Pass chest number correctly
              open: _opened,
              onAnimationComplete: () {
                if (!_cardsDealt && _inventoryItems.isNotEmpty) {
                  setState(() {
                    _cardsDealt = true;
                  });
                  // Add a small delay before starting card animations
                  Future.delayed(Duration(milliseconds: 200), () {
                    if (mounted && _currentCardIndex == -1) {
                      _startNextCardAnimation();
                    }
                  });
                }
              },
              onPreloadError: () {
                // Handle preload errors if necessary
                if (mounted) { // Ensure widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to load chest animation images.')),
                  );
                  widget.onClose();
                }
              },
            ),
          ),
          // Currently animating flying card
          if (_currentlyFlyingCard != null)
            FlyingCard(
              key: ValueKey(_currentCardIndex), // Add key to force rebuild
              item: _currentlyFlyingCard!,
              startX: widget.screenWidth / 2 - 25.0,
              startY: (widget.screenHeight / 2 - 200.0) + 100.0,
              centerX: _centerDisplayX,
              endX: _getFinalXPosition(_dealtCards.length),
              endY: _getFinalYPosition(_dealtCards.length),
              cardWidth: _cardWidth,
              cardHeight: _cardHeight,
              showStats: _showingStats,
              onCenterReached: () {
                setState(() {
                  _showingStats = true;
                });
                // Show stats for 1 second
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _showingStats = false;
                    });
                  }
                });
              },
              onAnimationComplete: _onCardAnimationComplete,
            ),
          // "Collect All" Button
          if (!_collecting && _dealtCards.isNotEmpty && !_animating)
            Positioned(
              bottom: 40,
              left: widget.screenWidth / 2 - 75, // Center horizontally
              child: ElevatedButton(
                onPressed: _collectCards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(150, 50), // Fixed width and height
                  elevation: 8, // Add shadow
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // More rounded corners
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Collect All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _skipCurrentCardAnimation() {
    if (_currentlyFlyingCard != null) {
      setState(() {
        _dealtCards.add(_currentlyFlyingCard!);
        _currentlyFlyingCard = null;
        _currentCardAnimationComplete = true;
        _showingStats = false;
      });

      // Start next card animation after a brief delay
      if (_currentCardIndex < _inventoryItems.length - 1) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _startNextCardAnimation();
        });
      } else {
        setState(() {
          _animating = false;
        });
      }
    }
  }

  double _getFinalXPosition(int index) {
    if (index < 3) { // First three cards go to the bottom row
      double totalWidthBottom = 3 * _cardWidth;
      double bottomRowXStart = (widget.screenWidth - totalWidthBottom) / 2;
      return bottomRowXStart + index * _cardWidth;
    } else { // Last two cards go to the top row
      double totalWidthTop = 2 * _cardWidth;
      double topRowXStart = (widget.screenWidth - totalWidthTop) / 2;
      return topRowXStart + (index - 3) * _cardWidth;
    }
  }

  double _getFinalYPosition(int index) {
    return index < 3 
        ? widget.screenHeight - 260.0  // Bottom row
        : widget.screenHeight - 400.0; // Top row
  }
}

class ChestCard extends StatelessWidget {
  final String chestName;
  final int chestPrice;
  final int chestNumber; // 1: Common, 2: Rare, 3: Epic
  final VoidCallback onChestTap;

  const ChestCard({
    Key? key,
    required this.chestName,
    required this.chestPrice,
    required this.chestNumber,
    required this.onChestTap,
  }) : super(key: key);

  String _getDisplayImagePath(int chestNumber) {
    switch (chestNumber) {
      case 1:
        return 'assets/images/chests/common/common-1.png';
      case 2:
        return 'assets/images/chests/rare/rare-1.png';
      case 3:
        return 'assets/images/chests/epic/epic-1.png';
      default:
        return 'assets/images/chests/common/common-1.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imagePath = _getDisplayImagePath(chestNumber);

    return Card(
      color: const Color.fromARGB(0, 48, 48, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onChestTap, // Use dynamic tap handler
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.asset(
                  imagePath,
                  height: 120, // Adjusted height
                  width: 120,  // Adjusted width
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image, size: 48, color: Colors.red[300]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chestName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "$chestPrice Coins",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
