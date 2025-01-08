import 'package:flutter/material.dart';
import 'package:workout_logger/inventory/inventory_page.dart';

class InventoryItemCard extends StatelessWidget {
  final String itemName;
  final String category;
  final String fileName;
  final bool isEquipped;
  final VoidCallback onEquipUnequip;
  final String rarity; // "common", "rare", "epic", "legendary"
  final bool showContent; // Controls whether to show the card's content
  final bool outOfChest;

  const InventoryItemCard({
    super.key,
    required this.itemName,
    required this.category,
    required this.fileName,
    required this.isEquipped,
    required this.onEquipUnequip,
    required this.rarity,
    this.showContent = true,
    this.outOfChest = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !outOfChest
          ? () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: false,
                builder: (context) => InventoryActionsDrawer(
                  itemName: itemName,
                  category: category,
                  fileName: fileName,
                  isEquipped: isEquipped,
                  onEquipUnequip: onEquipUnequip,
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getCardBackground(rarity)),
            fit: BoxFit.fill,
          ),
          border: isEquipped
              ? Border.all(
                  color: const Color.fromARGB(117, 255, 255, 0),
                  width: 2.0,
                )
              : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            if (showContent) ...[
              // Item name at the very top, smaller text
              Positioned(
                top: 7.0,
                right: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    itemName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10, // smaller text
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                    'assets/character/${category}/${fileName}${category != "armour" ? "_inv" : ""}.png',
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
              ),

              // Rarity at the very bottom
              Positioned(
                bottom: 16.0,
                left: 0,
                right: 0,
                child: Text(
                  capitalize(rarity),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCardBackground(String rarity) {
    switch (rarity) {
      case 'legendary':
        return 'assets/images/cards/legendary_card.png';
      case 'epic':
        return 'assets/images/cards/epic_card.png';
      case 'rare':
        return 'assets/images/cards/rare_card.png';
      case 'common':
      default:
        return 'assets/images/cards/common_card.png';
    }
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Helper function to get color based on rarity
  Color _getRarityColor() {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return const Color.fromARGB(255, 255, 5, 201); // Pinkish purple
      case 'rare':
        return const Color.fromARGB(255, 255, 255, 255); // White
      case 'common':
      default:
        return const Color(0xFFBEBEBE); // Grey
    }
  }
}
