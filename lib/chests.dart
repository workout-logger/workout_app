import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:workout_logger/item_card.dart';
import 'dart:math';
import 'animated_chest.dart';

class ChestsScreen extends StatefulWidget {
  ChestsScreen({Key? key}) : super(key: key);

  @override
  _ChestsScreenState createState() => _ChestsScreenState();
}

class _ChestsScreenState extends State<ChestsScreen> {
  final List<Map<String, dynamic>> chestData = [
    {'name': 'Bronze Chest', 'price': 100, 'number': 0},
    {'name': 'Silver Chest', 'price': 250, 'number': 1},
    {'name': 'Gold Chest', 'price': 500, 'number': 2},
    {'name': 'Diamond Chest', 'price': 1000, 'number': 3},
  ];

  OverlayEntry? _overlayEntry;
  final GlobalKey _bronzeChestKey = GlobalKey();

  void _onBronzeChestTap() {
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
        padding: const EdgeInsets.all(8.0),
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
      'rarity': 'common'
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
      'rarity': 'common'
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
              onTap: widget.onClose,
              child: Container(color: Colors.black),
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
              open: _opened, // Open state is fixed and does not toggle
              onAnimationComplete: () {
                if (!_cardsDealt) {
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

  double _getFinalXPosition(int index) {
    if (index < 2) {
      double totalWidthTop = 2 * _cardWidth;
      double topRowXStart = (widget.screenWidth - totalWidthTop) / 2;
      return topRowXStart + index * _cardWidth;
    } else {
      double totalWidthBottom = 3 * _cardWidth;
      double bottomRowXStart = (widget.screenWidth - totalWidthBottom) / 2;
      return bottomRowXStart + (index - 2) * _cardWidth;
    }
  }

  double _getFinalYPosition(int index) {
    return index < 2 
        ? widget.screenHeight - 340.0
        : widget.screenHeight - 200.0;
  }
}
class FlyingCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final double startX, startY;
  final double centerX;
  final double endX, endY;
  final double cardWidth, cardHeight;
  final bool showStats;
  final VoidCallback onCenterReached;
  final VoidCallback onAnimationComplete;

  const FlyingCard({
    Key? key,
    required this.item,
    required this.startX,
    required this.startY,
    required this.centerX,
    required this.endX,
    required this.endY,
    required this.cardWidth,
    required this.cardHeight,
    required this.showStats,
    required this.onCenterReached,
    required this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<FlyingCard> createState() => _FlyingCardState();
}

class _FlyingCardState extends State<FlyingCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasReachedCenter = false;
  bool _isMovingToFinal = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_hasReachedCenter) {
          _hasReachedCenter = true;
          widget.onCenterReached();
        } else if (_isMovingToFinal) {
          widget.onAnimationComplete();
        }
      }
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(FlyingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showStats && _hasReachedCenter && !_isMovingToFinal) {
      _isMovingToFinal = true;
      _controller.duration = const Duration(milliseconds: 800);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final centerY = screenHeight / 2 - (widget.cardHeight / 2);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double currentX, currentY;
        double scale = 1.0;

        if (!_hasReachedCenter) {
          // Moving to center
          currentX = lerpDouble(widget.startX, widget.centerX, _animation.value)!;
          currentY = lerpDouble(widget.startY, centerY, _animation.value)!;
          scale = lerpDouble(0.5, 1.0, _animation.value)!;
        } else if (!_isMovingToFinal) {
          // Holding at center
          currentX = widget.centerX;
          currentY = centerY;
          scale = 1.0;
        } else {
          // Moving to final position
          currentX = lerpDouble(widget.centerX, widget.endX, _animation.value)!;
          currentY = lerpDouble(centerY, widget.endY, _animation.value)!;
          scale = lerpDouble(1.0, 0.8, _animation.value)!;
        }

        return Stack(
          children: [
            Positioned(
              left: currentX,
              top: currentY,
              width: widget.cardWidth,
              height: widget.cardHeight,
              child: Transform.scale(
                scale: scale,
                child: InventoryItemCard(
                  rarity: widget.item['rarity'],
                  itemName: widget.item['itemName'],
                  category: widget.item['category'],
                  fileName: widget.item['fileName'],
                  isEquipped: widget.item['isEquipped'],
                  onEquipUnequip: () {},
                ),
              ),
            ),
            if (widget.showStats && _hasReachedCenter && !_isMovingToFinal)
              Positioned(
                left: currentX + widget.cardWidth + 20.0,
                top: currentY,
                child: _buildStatsWidget(widget.item),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatsWidget(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatBar("Attack", Random().nextInt(100)),
        _buildStatBar("Defense", Random().nextInt(100)),
        _buildStatBar("Durability", Random().nextInt(100)),
      ],
    );
  }

  Widget _buildStatBar(String statName, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 60.0,
            child: Text(
              statName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Container(
            width: 100.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: value / 100.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ],
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
          if (chestNumber == 0) {
            // Bronze chest: animate to center and open
            onBronzeChestTap();
          } else {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$chestName purchased!',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Buy', style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            );
          }
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
