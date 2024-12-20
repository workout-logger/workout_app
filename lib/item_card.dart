import 'dart:math';
import 'package:flutter/material.dart';
import 'package:workout_logger/inventory_page.dart';

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
  int _lastSegment = -1;

  // For legendary sudden color changes, store current colors
  Color _legendaryColor1 = const Color.fromARGB(255, 209, 201, 245)!;
  Color _legendaryColor2 = const Color.fromARGB(255, 175, 245, 134);

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // For epic and legendary, we animate. For others, it's static but still use the controller for legendary updates.
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
        // Legendary: Dark colors, random sudden changes
        // We divide animation into segments. On each segment, pick new colors.
        double t = sin(_animation.value * pi);
        Color color1 = Color.lerp(const Color.fromARGB(255, 146, 226, 250), const Color.fromARGB(255, 228, 236, 113), t)!;
        Color color2 = Color.lerp(Colors.indigo[900], Colors.pink[900], 1 - t)!;
        return LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      case 'epic':
        // Epic: Purples/pinks but let's keep them static now or slightly animated without sudden changes
        double t = sin(_animation.value * pi);
        Color color1 = Color.lerp(Colors.deepPurple[700], Colors.purple[900], t)!;
        Color color2 = Color.lerp(Colors.indigo[900], Colors.pink[900], 1 - t)!;
        return LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

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

  Color _randomDarkColor() {
    // Generate a random dark color
    // Dark color: low brightness, random hue
    int r = _random.nextInt(50); // 0-50 for dark
    int g = _random.nextInt(50);
    int b = _random.nextInt(50);
    return Color.fromRGBO(r, g, b, 1.0);
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
              // For non-legendary, normal shape:
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
                        color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
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
                  ),
              ],
            ),
          );

          if (widget.rarity == 'legendary') {
            // Clip into a hexagon for legendary
            cardContent = ClipPath(
              clipper: HexClipper(),
              child: cardContent,
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
                bottom: 8.0,
                left: 0,
                right: 0,
                child: Text(
                  widget.itemName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// A custom clipper for a hexagonal shape
class HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Create a more stylized hexagon with inward curves
    double w = size.width;
    double h = size.height;
    
    Path path = Path();
    path.moveTo(w * 0.3, 0); // top-left corner moved in
    path.lineTo(w * 0.7, 0); // straight top shortened
    path.lineTo(w, h * 0.2); // right upper edge shortened
    path.quadraticBezierTo(w * 1.1, h * 0.5, w, h * 0.8); // curved right side lengthened
    path.lineTo(w * 0.7, h); // bottom-right corner moved in
    path.lineTo(w * 0.3, h); // straight bottom shortened
    path.lineTo(0, h * 0.8); // left lower edge shortened
    path.quadraticBezierTo(w * -0.1, h * 0.5, 0, h * 0.2); // curved left side lengthened
    path.close();
    return path;
  }

  @override
  bool shouldReclip(HexClipper oldClipper) => false;
}
