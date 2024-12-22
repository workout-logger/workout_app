import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:workout_logger/item_card.dart';

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
  State<FlyingCard> createState() => FlyingCardState();
}

class FlyingCardState extends State<FlyingCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _flipController;
  late Animation<double> _pathAnimation;
  late Animation<double> _flipAnimation;
  bool _hasReachedCenter = false;
  bool _isMovingToFinal = false;
  bool _showContent = false;


  late Duration pathDuration;
  late Duration flipDuration;
  late Duration skipDuration;

  @override
  void initState() {
    super.initState();

    switch (widget.item['rarity']?.toString().toLowerCase()) {
      case 'common':
        pathDuration = const Duration(milliseconds: 500);
        flipDuration = const Duration(milliseconds: 500);
        skipDuration = const Duration(milliseconds: 1000);
        break;
      case 'rare':
        pathDuration = const Duration(milliseconds: 600);
        flipDuration = const Duration(milliseconds: 600);
        skipDuration = const Duration(milliseconds: 1200);
        break;
      case 'epic':
        pathDuration = const Duration(milliseconds: 800);
        flipDuration = const Duration(milliseconds: 800);
        skipDuration = const Duration(milliseconds: 1600);
        break;
      default:
        pathDuration = const Duration(milliseconds: 1500);
        flipDuration = const Duration(milliseconds: 3000);
        skipDuration = const Duration(milliseconds: 4500);
        break;

    }

    _controller = AnimationController(
      duration: pathDuration,
      vsync: this,
    );

    _flipController = AnimationController(
      duration: flipDuration,
      vsync: this,
    );

    _pathAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 6 * pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutQuad),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_hasReachedCenter) {
          _hasReachedCenter = true;
        } else if (_isMovingToFinal) {
          widget.onAnimationComplete();
        }
      }
    });

    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _hasReachedCenter && !_isMovingToFinal) {
        setState(() {
          _showContent = true;
        });
        widget.onCenterReached();
      }
    });

    _controller.forward();
  }

  void _startCenterFlips() {
    _flipController.forward();
  }

  void skipAnimation() {
    if (!_isMovingToFinal) {
      _flipController.stop();
      setState(() {
        _showContent = true;
        _isMovingToFinal = true;
      });
      _controller.duration = skipDuration;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(FlyingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showStats && _hasReachedCenter && !_isMovingToFinal) {
      _isMovingToFinal = true;
      _controller.duration = skipDuration;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final centerY = screenHeight / 2 - (widget.cardHeight / 2);

    return GestureDetector(
      onTapDown: (_) => skipAnimation(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pathAnimation, _flipAnimation]),
        builder: (context, child) {
          double currentX, currentY;
          double scale = 1.0;

          if (!_hasReachedCenter) {
            _startCenterFlips();

            // Arc path to center
            final progress = _pathAnimation.value;
            final arcHeight = 200.0;
            
            currentX = lerpDouble(widget.startX, widget.centerX, progress)!;
            final directY = lerpDouble(widget.startY, centerY, progress)!;
            final parabolaY = -arcHeight * 4 * (progress - 0.5) * (progress - 0.5) + arcHeight;
            currentY = directY - parabolaY;
            
            scale = lerpDouble(0.5, 1.0, progress)!;
          } else if (!_isMovingToFinal) {
            currentX = widget.centerX;
            currentY = centerY;
            scale = 1.0;
          } else {
            currentX = lerpDouble(widget.centerX, widget.endX, _pathAnimation.value)!;
            currentY = lerpDouble(centerY, widget.endY, _pathAnimation.value)!;
            scale = lerpDouble(1.0, 0.8, _pathAnimation.value)!;
          }

          return Stack(
            children: [
              Positioned(
                left: currentX,
                top: currentY,
                width: widget.cardWidth,
                height: widget.cardHeight,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipAnimation.value)
                    ..scale(scale),
                  alignment: Alignment.center,
                  child: _showContent 
                    ? InventoryItemCard(
                        rarity: widget.item['rarity'],
                        itemName: widget.item['itemName'],
                        category: widget.item['category'],
                        fileName: widget.item['fileName'],
                        isEquipped: widget.item['isEquipped'],
                        onEquipUnequip: () {
                          // Your equip/unequip logic here
                        },
                        showContent: true, // Explicitly showing content
                      )
                    : InventoryItemCard(
                        rarity: widget.item['rarity'],
                        itemName: widget.item['itemName'],
                        category: widget.item['category'],
                        fileName: widget.item['fileName'],
                        isEquipped: widget.item['isEquipped'],
                        onEquipUnequip: () {}, // Empty callback
                        showContent: false, // Hiding content
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
      ),
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
