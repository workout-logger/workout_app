import 'dart:convert';
import 'dart:ui';
import 'package:workout_logger/inventory/inventory_manager.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_logger/currency_provider.dart';
import 'package:workout_logger/flying_card.dart';
import 'package:workout_logger/inventory/item_card.dart';
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
    {'name': 'Bronze Chest', 'price': 100, 'number': 0},
  ];

  OverlayEntry? _overlayEntry;
  final GlobalKey _bronzeChestKey = GlobalKey();

  void _onBronzeChestTap() {
    // Access the current currency from the provider
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    const double chestCost = 100.0; // Example cost for opening the chest
    print(currencyProvider.currency);
    if (currencyProvider.currency < chestCost) {
      // Show an error message or feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough currency to open the chest!'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit if the user doesn't have enough currency
    }


    // Proceed with opening the chest
    AnimatedChest.setHasAnimated(false);
    print("Chest tapped!");

    final RenderBox? box = _bronzeChestKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      print("Error: Couldn't find chest position");
      return;
    }

    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = MediaQuery.of(context).size;

    // Create and insert overlay
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => _ChestOverlay(
        initialX: position.dx,
        initialY: position.dy,
        screenWidth: size.width,
        screenHeight: size.height,
        onClose: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: chestData.length,
          itemBuilder: (context, index) {
            final chest = chestData[index];
            final key = (chest['number'] == 0) ? _bronzeChestKey : null;
            return ChestCard(
              key: key,
              chestName: chest['name'],
              chestPrice: chest['price'],
              chestNumber: chest['number'],
              onBronzeChestTap: _onBronzeChestTap,
            );
          },
        ),
      ),
    );
  }
}


class _ChestOverlay extends StatefulWidget {
  final double initialX;
  final double initialY;
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onClose;

  const _ChestOverlay({
    required this.initialX,
    required this.initialY,
    required this.screenWidth,
    required this.screenHeight,
    required this.onClose,
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

  final int _cardCount = 5;
  final double _cardWidth = 120.0;
  final double _cardHeight = 150.0;
  bool _currentCardAnimationComplete = true;
  Map<String, dynamic>? _currentlyFlyingCard;

  final List<Map<String, dynamic>> _inventoryItems = [
  ];

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
          'chest_id': "1",
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body)['items'];
        
        // Add the received items to the inventory
        setState(() {
          _inventoryItems.addAll(items.map((item) => {
            'itemName': item['itemName'],
            'category': item['category'],
            'fileName': item['fileName'],
            'isEquipped': false, // Default state
            'rarity': item['rarity'],
          }));
        });
        InventoryManager().requestInventoryUpdate();


        return items;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to purchase chest: ${json.decode(response.body)['message']}')),
        );
        return null;
      }
    } catch (e) {
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _centered = true;
          });
        }
      });
    });
    _buyChest();
    
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
    if (_currentCardIndex < _cardCount - 1 && _currentCardAnimationComplete) {
      setState(() {
        _currentCardIndex++;
        _currentlyFlyingCard = _inventoryItems[_currentCardIndex];
        _currentCardAnimationComplete = false;
        _showingStats = false;
      });
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
      if (_currentCardIndex < _cardCount - 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _startNextCardAnimation();
        });
      }else{
        _animating = false;
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _centered ? 0.7 : 0.0,
            child: GestureDetector(
              onTap: () {
                // Only allow closing if no card animation is in progress

              },
              child: Container(color: Colors.black),
            ),
          ),
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
          }),
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
            }),

          // Regular dealt cards
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
            }),
          // Chest
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            left: _centered ? widget.screenWidth / 2 - 100.0 : widget.initialX,
            top: _centered ? widget.screenHeight / 2 - 200.0 : widget.initialY,
            width: _centered ? 200.0 : 100.0,
            height: _centered ? 200.0 : 100.0,
            onEnd: () {
              if (_centered && !_opened) {
                setState(() {
                  _opened = true; // Ensure _opened is set only once
                });
              }
            },
            child: AnimatedChest(
              open: _opened,
              onAnimationComplete: () {
                if (!_cardsDealt) {
                  print("Animation complete!");
                  setState(() {
                    _cardsDealt = true;
                  });
                  print(_currentCardIndex);
                  if (_currentCardIndex == -1) {
                    _startNextCardAnimation();
                  }
                }
              },
            ),
          ),



          // Currently animating card
          if (_currentlyFlyingCard != null)
            FlyingCard(
              key: ValueKey(_currentCardIndex), // Add key to force rebuild
              item: _inventoryItems[_currentCardIndex],
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
                // Show stats for 2 seconds
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
        if (_currentCardIndex < _cardCount - 1) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _startNextCardAnimation();
          });
        }else{
         _animating = false;
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
  final int chestNumber;
  final VoidCallback onBronzeChestTap;

  const ChestCard({
    super.key,
    required this.chestName,
    required this.chestPrice,
    required this.chestNumber,
    required this.onBronzeChestTap,
  });

  @override
  Widget build(BuildContext context) {
    final String imagePath = (chestNumber == 0)
        ? 'assets/images/chests/tile000.png'
        : 'assets/images/Pixel_Chest_Pack/chest_$chestNumber.png';

    return Card(
      color: const Color.fromARGB(0, 48, 48, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Show purchase dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Purchase $chestName',
                style: const TextStyle(color: Colors.white),
              ),
              content: Text(
                'Do you want to buy this chest for $chestPrice coins?',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onBronzeChestTap();
                  },
                  child: const Text('Buy', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          );
        },
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
