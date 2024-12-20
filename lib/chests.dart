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
  List<bool> _cardAnimationsStarted = [];

  final int _cardCount = 5; 
  final double _cardSpacing = 0.0; 
  final double _cardWidth = 120.0;
  final double _cardHeight = 150.0;

  final List<Map<String, dynamic>> inventoryItems = [
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

  @override
  void initState() {
    super.initState();
    _cardAnimationsStarted = List.filled(_cardCount, false);

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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Dim
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _centered ? 0.7 : 0.0,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black),
            ),
          ),

          // Chest positioned higher
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            left: _centered ? widget.screenWidth / 2 - 100.0 : widget.initialX,
            top: _centered ? widget.screenHeight / 2 - 200.0 : widget.initialY,
            width: _centered ? 200.0 : 100.0,
            height: _centered ? 200.0 : 100.0,
            onEnd: () {
              // Once centered
              if (_centered && !_opened) {
                setState(() {
                  _opened = true;
                });
              }
            },
            child: _opened
                ? AnimatedChest(
                    open: true,
                    onAnimationComplete: () {
                      // Chest is fully opened, start dealing cards
                      setState(() {
                        _cardsDealt = true;
                      });
                      // Stagger card animations
                      for (int i = 0; i < _cardCount; i++) {
                        Future.delayed(Duration(milliseconds: 800 * i), () {
                          if (mounted) {
                            setState(() {
                              _cardAnimationsStarted[i] = true;
                            });
                          }
                        });
                      }
                    },
                  )
                : Image.asset(
                    'assets/images/chests/tile000.png',
                    fit: BoxFit.contain,
                  ),
          ),

          // Cards
          if (_cardsDealt) ..._buildCardWidgets(),
        ],
      ),
    );
  }

  List<Widget> _buildCardWidgets() {
    // Cards start from chest area
    final double cardStartX = widget.screenWidth / 2 - 25.0;
    final double cardStartY = (widget.screenHeight / 2 - 200.0) + 100.0; 

    double totalWidthTop = 2 * _cardWidth + 1 * _cardSpacing;
    double topRowXStart = (widget.screenWidth - totalWidthTop) / 2;
    double topRowY = widget.screenHeight - 200.0 - 140.0; 
    double totalWidthBottom = 3 * _cardWidth + 2 * _cardSpacing;
    double bottomRowXStart = (widget.screenWidth - totalWidthBottom) / 2;
    double bottomRowY = widget.screenHeight - 200.0;

    return List.generate(_cardCount, (i) {
      final delayStarted = _cardAnimationsStarted[i];
      final item = inventoryItems[i];

      if (!delayStarted) {
        return const SizedBox.shrink();
      }

      double finalX, finalY;
      if (i < 2) {
        finalX = topRowXStart + i * (_cardWidth + _cardSpacing);
        finalY = topRowY;
      } else {
        int j = i - 2;
        finalX = bottomRowXStart + j * (_cardWidth + _cardSpacing);
        finalY = bottomRowY;
      }

      return FlyingCard(
        key: ValueKey(i),
        item: item,
        startX: cardStartX,
        startY: cardStartY,
        endX: finalX,
        endY: finalY,
        isAnimating: delayStarted,
        cardWidth: _cardWidth,
        cardHeight: _cardHeight,
      );
    });
  }
}

class FlyingCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final double startX, startY;
  final double endX, endY;
  final bool isAnimating;
  final double cardWidth, cardHeight;

  const FlyingCard({
    Key? key,
    required this.item,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.isAnimating,
    required this.cardWidth,
    required this.cardHeight,
  }) : super(key: key);

  @override
  State<FlyingCard> createState() => _FlyingCardState();
}

class _FlyingCardState extends State<FlyingCard> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bool isLegendary = item['rarity'] == 'legendary';

    if (!widget.isAnimating) {
      return const SizedBox.shrink();
    }

    // Different durations:
    // - Legendary: 8 seconds (8000ms)
    // - Non-legendary: quick, say 2 seconds (2000ms)
    final totalDuration = isLegendary ? 8000 : 2000;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      // Use different duration depending on rarity
      duration: Duration(milliseconds: totalDuration),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        final centerX = screenWidth / 2 - (widget.cardWidth / 2);
        final centerY = screenHeight / 2 - (widget.cardHeight / 2);

        double currentX, currentY;
        double scale;
        double rotationY = 0.0; 
        double rotationZ = 0.0; 

        if (!isLegendary) {
          // Non-legendary: just 2 phases over 2s
          if (value <= 0.5) {
            double t = value / 0.5;
            currentX = lerpDouble(widget.startX, centerX, t)!;
            currentY = lerpDouble(widget.startY, centerY, t)!;
            scale = lerpDouble(0.5, 1.2, t)!;
            rotationZ = lerpDouble(-0.2, 0.0, t)!;
          } else {
            double t = (value - 0.5) / 0.5;
            currentX = lerpDouble(centerX, widget.endX, t)!;
            currentY = lerpDouble(centerY, widget.endY, t)!;
            scale = lerpDouble(1.2, 0.8, t)!;
            rotationZ = 0.0;
          }
          rotationY = 0.0;
        } else {
          // Legendary: longer 8s phases (same as previous code)
          if (value <= 0.3) {
            double t = value / 0.3;
            currentX = lerpDouble(widget.startX, centerX, t)!;
            currentY = lerpDouble(widget.startY, centerY, t)!;
            scale = lerpDouble(0.3, 1.3, t)!;
            rotationZ = lerpDouble(-1, 0, t)!;
            rotationY = t * 4 * pi; 
          } else if (value <= 0.5) {
            double t = (value - 0.3) / 0.2; 
            currentX = centerX;
            currentY = centerY;
            scale = 1.3;
            rotationZ = 0.0;
            rotationY = 4 * pi + t * 8 * pi; 
          } else if (value <= 0.9) {
            double t = (value - 0.5) / 0.3;
            currentX = centerX;
            currentY = centerY;
            double wiggle = sin(t * 2 * pi) * 0.1; 
            scale = 1.3 + wiggle;
            rotationZ = sin(t * 2 * pi) * 0.2;
            rotationY = 0.0;
          } else {
            double t = (value - 0.9) / 0.1;
            currentX = lerpDouble(centerX, widget.endX, t)!;
            currentY = lerpDouble(centerY, widget.endY, t)!;
            scale = lerpDouble(1.3, 0.8, t)!;
            rotationZ = 0.0;
            rotationY = 0.0;
          }
        }

        final transform = Matrix4.identity()
          ..rotateZ(rotationZ)
          ..rotateY(rotationY);

        return Positioned(
          left: currentX,
          top: currentY,
          width: widget.cardWidth,
          height: widget.cardHeight,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Transform.scale(
              scale: scale,
              child: InventoryItemCard(
                rarity: item['rarity'],
                itemName: item['itemName'],
                category: item['category'],
                fileName: item['fileName'],
                isEquipped: item['isEquipped'],
                onEquipUnequip: () {
                  print('${item['itemName']} equipped/unequipped!');
                },
              ),
            ),
          ),
        );
      },
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
