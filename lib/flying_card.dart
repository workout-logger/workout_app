import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:workout_logger/inventory/item_card.dart';

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
  bool _showStats = false;

  // **Stats Animation Controllers and Animations**
  late AnimationController _statsSlideController;
  late AnimationController _statsBarController;
  late Animation<Offset> _statsSlideAnimation;
  late Animation<double> _statsBarAnimation;


  late Duration pathDuration;
  late Duration flipDuration;
  late Duration skipDuration;
  @override
  void initState() {
    super.initState();

    // Determine durations based on rarity
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
        pathDuration = const Duration(milliseconds: 1300);
        flipDuration = const Duration(milliseconds: 1400);
        skipDuration = const Duration(milliseconds: 4500);
        break;
    }

    // Path Animation Controller
    _controller = AnimationController(
      duration: pathDuration,
      vsync: this,
    );

    _pathAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Flip Animation Controller
    _flipController = AnimationController(
      duration: flipDuration,
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 6 * pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutQuad),
    );

    // **Initialize Stats Animation Controllers**
    _statsSlideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _statsBarController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _statsSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _statsSlideController,
      curve: Curves.easeOutCubic,
    ));

    _statsBarAnimation = CurvedAnimation(
      parent: _statsBarController,
      curve: Curves.easeInOut,
    );

    // Listeners
    _controller.addStatusListener((status) {
      _startFlipAnimation();
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
        print("Flip completed, showing content");
        setState(() {
          _showContent = true;
        });
        widget.onCenterReached();

        if (widget.showStats) {
          _startStatsAnimations();
        }
      }
    });

    _controller.forward();
  }

  void _startFlipAnimation() {
    _flipController.forward();
  }

  // **Function to Start Stats Animations**
  void _startStatsAnimations() {
    setState(() {
      _showStats = true; // Ensure stats visibility
      print("Stats are now visible.");
    });

    // Start the stats slide and bar animations
    _statsSlideController.forward();
    _statsBarController.forward();

    // Listen for completion of the stats bar animation
    _statsBarController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Proceed to final animation with a slight delay for visibility
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _showStats = false; // Hide stats
            print("Stats are now hidden.");
            _isMovingToFinal = true;
          });

          // Start the path animation to the final position
          _controller.duration = skipDuration;
          _controller.forward(from: 0.0);
        });
      }
    });
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
    if (!widget.showStats && _hasReachedCenter && _isMovingToFinal) {
      _isMovingToFinal = true;
      _controller.duration = skipDuration;
      _controller.forward(from: 0.0);
    }

    // **Handle Changes to showStats Dynamically**
    if (widget.showStats && !_isMovingToFinal && _hasReachedCenter && !_statsSlideController.isAnimating && !_statsBarController.isAnimating) {
      _startStatsAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flipController.dispose();
    _statsSlideController.dispose();
    _statsBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final centerY = screenHeight / 2 - (widget.cardHeight / 2);

    return GestureDetector(
      onTapDown: (_) => skipAnimation(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pathAnimation, _flipAnimation, _statsSlideController, _statsBarController]),
        builder: (context, child) {
          double currentX, currentY;
          double scale = 1.0;

          if (!_hasReachedCenter) {
            // **Arc Path to Center**
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
              // **Card Positioning and Transformation**
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
                        itemName: "",
                        category: widget.item['category'],
                        fileName: widget.item['fileName'],
                        isEquipped: widget.item['isEquipped'],
                        onEquipUnequip: () {
                          // Your equip/unequip logic here
                        },
                        showContent: true, 
                        outOfChest: true,// Explicitly showing content
                      )
                    : InventoryItemCard(
                        rarity: widget.item['rarity'],
                        itemName: "",
                        category: widget.item['category'],
                        fileName: widget.item['fileName'],
                        isEquipped: widget.item['isEquipped'],
                        onEquipUnequip: () {}, // Empty callback
                        showContent: false, // Hiding content
                        outOfChest: true,
                      ),
                ),
              ),

              // **Stats Display Positioned Relative to Card**
              if (_showStats)
                Positioned(
                  left: currentX + widget.cardWidth + 10,  // Added 10 for padding
                  top: currentY,
                  child: SlideTransition(
                    position: _statsSlideAnimation,
                    child: _buildStatsWidget(widget.item),
                  ),
                ),

            ],
          );
        },
      ),
    );
  }

  Color _getCardBorderColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatsWidget(Map<String, dynamic> item) {
    Color backgroundColor = widget.item['rarity']?.toLowerCase() == 'common' ? Color.fromARGB(111, 68, 68, 68) :
                          widget.item['rarity']?.toLowerCase() == 'rare' ? Color.fromARGB(141, 62, 92, 56) :
                          widget.item['rarity']?.toLowerCase() == 'epic' ? Color.fromARGB(255, 80, 76, 76) :
                          Color.fromARGB(255, 146, 226, 250);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getCardBorderColor(widget.item['rarity']),
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatBar("Strength", "+4", 0.8),
          const SizedBox(height: 12.0),
          _buildStatBar("Agility", "+2", 0.4),
          const SizedBox(height: 12.0),
          _buildStatBar("Vitality", "+3", 0.6),
        ],
      ),
    );
  }

  Widget _buildStatBar(String statName, String bonus, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80.0,
              child: Text(
                statName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              bonus,
              style: TextStyle(
                color: Colors.green[400],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Container(
          width: 160.0,
          height: 12.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.item['rarity']?.toLowerCase() == 'common' ? [Color.fromARGB(112, 156, 156, 156), Color.fromARGB(100, 78, 78, 78)] :
                     widget.item['rarity']?.toLowerCase() == 'rare' ? [Color.fromARGB(141, 42, 61, 38), Color.fromARGB(104, 15, 92, 0)] :
                     widget.item['rarity']?.toLowerCase() == 'epic' ? [Color.fromARGB(255, 80, 76, 76), Color.fromARGB(255, 94, 2, 94)] :
                     [Color.fromARGB(255, 146, 226, 250), Color.fromARGB(255, 228, 236, 113)],
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: FractionallySizedBox(
            widthFactor: value * _statsBarAnimation.value, // Animate width based on controller
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green[400]!,
                    Colors.green[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(6.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


}
