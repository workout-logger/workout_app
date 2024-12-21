import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:workout_logger/inventory_page.dart';

// A function that returns a perfect hexagonal path based on size.
Path getHexPath(Size size) {
  double w = size.width;
  double h = size.height;

  Path path = Path();
  path.moveTo(w * 0.5, 0);
  path.lineTo(w, h * 0.1);
  path.lineTo(w, h * 0.9);
  path.lineTo(w * 0.5, h);
  path.lineTo(0, h * 0.9);
  path.lineTo(0, h * 0.1);
  path.close();
  return path;
}

class InventoryItemCard extends StatefulWidget {
  final String itemName;
  final String category;
  final String fileName;
  final bool isEquipped;
  final VoidCallback onEquipUnequip;
  final String rarity; // "common", "rare", "epic", "legendary"

  const InventoryItemCard({
    super.key,
    required this.itemName,
    required this.category,
    required this.fileName,
    required this.isEquipped,
    required this.onEquipUnequip,
    required this.rarity,
  });

  @override
  State<InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends State<InventoryItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // For epic and legendary, we animate. For others, it's static.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Gradient _buildGradient() {
    switch (widget.rarity) {
      case 'legendary':
        {
          double t = sin(_animation.value * pi);
          Color color1 = Color.lerp(
            const Color.fromARGB(255, 146, 226, 250),
            const Color.fromARGB(255, 228, 236, 113),
            t,
          )!;
          Color color2 = Color.lerp(Colors.indigo[900], Colors.pink[900], 1 - t)!;
          return LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }
      case 'epic':
        {
          double t = sin(_animation.value * pi);
          Color color1 =
              Color.lerp(Colors.deepPurple[700], Colors.purple[900], t)!;
          Color color2 =
              Color.lerp(Colors.indigo[900], Colors.pink[900], 1 - t)!;
          return LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }
      case 'rare':
        return const LinearGradient(
          colors: [Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      case 'common':
      default:
        return const LinearGradient(
          colors: [Color(0xFF2F2F2F), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('Category: ${widget.category}');
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => InventoryActionsDrawer(
            itemName: widget.itemName,
            category: widget.category,
            fileName: widget.fileName,
            isEquipped: widget.isEquipped,
            onEquipUnequip: widget.onEquipUnequip,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          Widget cardContent = Container(
            decoration: BoxDecoration(
              gradient: _buildGradient(),
              borderRadius: widget.rarity == 'legendary' ? null : BorderRadius.circular(10),
              border: Border.all(
                color: widget.isEquipped
                    ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2)
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: widget.isEquipped
                  ? [
                      BoxShadow(
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.category == "legs" || widget.category == "melee")
                  ClipRect(
                    child: SizedBox(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: 0.3,
                        child: Image.asset(
                          'assets/character/${widget.category}/${widget.fileName}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image,
                              color: Colors.redAccent,
                              size: 60,
                            );
                          },
                        ),
                      ),
                    ),
                  )
                else if (widget.category == "wings")
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 45.0),
                    child: Image.asset(
                      'assets/character/${widget.category}/${widget.fileName}',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.redAccent,
                          size: 40,
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 30.0),
                    child: Image.asset(
                      'assets/character/${widget.category}/${widget.fileName}',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.redAccent,
                          size: 40,
                        );
                      },
                    ),
                  )
              ],
            ),
          );

          // For legendary, clip and add a matching border + moving dot
          if (widget.rarity == 'legendary') {
            cardContent = Stack(
              children: [
                ClipPath(
                  clipper: HexClipper(),
                  child: cardContent,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: CustomPaint(
                      painter: HexBorderWithDotPainter(animationValue: _animation.value),
                    ),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              cardContent,
              if (widget.isEquipped)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.deepPurpleAccent.withOpacity(0.7),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 16.0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      widget.itemName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.rarity == 'legendary' ? Colors.white : Colors.white70,
                        fontSize: widget.rarity == 'legendary' ? 16 : 14,
                        fontWeight: widget.rarity == 'legendary' ? FontWeight.bold : FontWeight.normal,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: widget.rarity == 'legendary' ? 8 : 4,
                            color: widget.rarity == 'legendary' ? Colors.black87 : Colors.black,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      capitalize(widget.rarity),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRarityColor(),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Helper function to get color based on rarity
  Color _getRarityColor() {
    switch (widget.rarity) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return const Color(0xFF800080); // Purple
      case 'rare':
        return const Color(0xFF4169E1); // Royal Blue
      case 'common':
      default:
        return const Color(0xFFBEBEBE); // Grey
    }
  }
}

// A custom clipper using the same hex path
class HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return getHexPath(size);
  }

  @override
  bool shouldReclip(HexClipper oldClipper) => false;
}

// Painter for the hex border with a moving dot along the path
class HexBorderWithDotPainter extends CustomPainter {
  final double animationValue;

  HexBorderWithDotPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    var path = getHexPath(size);

    // Draw shimmering border with gradient
    final borderGradient = SweepGradient(
      colors: [
        const Color.fromARGB(255, 255, 0, 0).withOpacity(0.2),
        Colors.blue.withOpacity(0.4), 
        Colors.cyan.withOpacity(0.6),
        Colors.purple.withOpacity(0.2),
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
      transform: GradientRotation(animationValue * 2 * pi),
    );

    var borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..shader = borderGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);

    canvas.drawPath(path, borderPaint);

    // Add glowing effect
    var glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);

    // Compute path for moving dot
    PathMetric pathMetric = path.computeMetrics().first;
    double pathLength = pathMetric.length;
    double currentOffset = pathLength * animationValue;

    // Get dot position
    Tangent? tangent = pathMetric.getTangentForOffset(currentOffset);
    if (tangent == null) return;
    Offset dotPosition = tangent.position;

    // Create trailing effect
    double trailLength = pathLength * 0.2;
    double startOffset = (currentOffset - trailLength).clamp(0.0, pathLength);
    Path trailPath = pathMetric.extractPath(startOffset, currentOffset);

    // Draw shimmering trail
    var trailGradient = LinearGradient(
      colors: [
        const Color.fromARGB(255, 255, 0, 0).withOpacity(0.0),
        Colors.cyan.withOpacity(0.3),
        Colors.blue.withOpacity(0.5),
        Colors.purple.withOpacity(0.8),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    // Multi-layer trail effect
    for (int i = 1; i <= 4; i++) {
      Paint trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0 / i
        ..shader = trailGradient.createShader(
            Rect.fromPoints(tangent.position, 
                tangent.position.translate(trailLength, 0)))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * i.toDouble());

      canvas.drawPath(trailPath, trailPaint);
    }

    // Draw glowing dot
    for (double i = 4; i > 0; i--) {
      var dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.8 / i)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 3);
      
      canvas.drawCircle(dotPosition, 6.0 * i, dotPaint);
    }

    // Add center highlight to dot
    canvas.drawCircle(
      dotPosition,
      3.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
    );
  }

  @override
  bool shouldRepaint(HexBorderWithDotPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

