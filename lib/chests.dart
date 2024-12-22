import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:workout_logger/flying_card.dart';
import 'package:workout_logger/item_card.dart';
import 'animated_chest.dart';

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
  final List<Map<String, dynamic>> _dealtCards = [];

  final int _cardCount = 5;
  final double _cardWidth = 120.0;
  final double _cardHeight = 150.0;
  bool _currentCardAnimationComplete = true;
  Map<String, dynamic>? _currentlyFlyingCard;

  final List<Map<String, dynamic>> _inventoryItems = [
    {
      'itemName': 'Iron Sword',
      'category': 'melee',
      'fileName': 'sword_iron.png',
      'isEquipped': false,
      'rarity': 'epic'
    },
    {
      'itemName': 'Blue Pants',
      'category': 'legs',
      'fileName': 'pants_blue.png',
      'isEquipped': false,
      'rarity': 'common'
    },
    {
      'itemName': 'Blue Head',
      'category': 'heads',
      'fileName': 'head_blue.png',
      'isEquipped': false,
      'rarity': 'rare'
    },
    {
      'itemName': 'Other Blue Pants',
      'category': 'legs',
      'fileName': 'pants_blue.png',
      'isEquipped': false,
      'rarity': 'common'
    },
    {
      'itemName': 'Amber Wings',
      'category': 'wings',
      'fileName': 'wings_amber.png',
      'isEquipped': false,
      'rarity': 'legendary'
    },
  ];

  late final double _centerDisplayX;
  final double _statsOffset = 200.0;

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
                if (_currentlyFlyingCard == null) {
                  widget.onClose();
                }
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
        ? widget.screenHeight - 200.0  // Bottom row
        : widget.screenHeight - 340.0; // Top row
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
          // Other chests: show purchase dialog
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Image.asset(
                imagePath,
                height: 100,
                width: 100,
                fit: BoxFit.contain,
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
