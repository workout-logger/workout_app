import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CharacterStatsView extends StatelessWidget {
  final String head;
  final String armour;
  final String legs;
  final String melee;
  final String arms;
  final String wings;
  final Map<String, dynamic> stats;

  const CharacterStatsView({
    super.key,
    required this.head,
    required this.armour,
    required this.legs,
    required this.melee,
    required this.arms,
    required this.wings,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dynamic stats list using the stats parameter
    final List<Map<String, dynamic>> dynamicStats = [
      {
        'title': 'STR',
        'value': stats['strength'] ?? 0,
        'color': HexColor('#FF6B78').withOpacity(0.85),
        'icon': Icons.fitness_center,
        'angle': 0.0,
      },
      {
        'title': 'SPD',
        'value': stats['speed'] ?? 0,
        'color': HexColor('#738AE6').withOpacity(0.85),
        'icon': Icons.flash_on,
        'angle': 60.0,
      },
      {
        'title': 'AGI',
        'value': stats['agility'] ?? 0,
        'color': HexColor('#87A0E5').withOpacity(0.85),
        'icon': Icons.directions_walk,
        'angle': 120.0,
      },
      {
        'title': 'END',
        'value': stats['defence'] ?? 0,
        'color': HexColor('#FFA726').withOpacity(0.85),
        'icon': Icons.shield,
        'angle': 180.0,
      },
      {
        'title': 'INT',
        'value': stats['intelligence'] ?? 0,
        'color': HexColor('#FE95B6').withOpacity(0.85),
        'icon': Icons.lightbulb_outline,
        'angle': 240.0,
      },
      {
        'title': 'VIS',
        'value': stats['stealth'] ?? 0,
        'color': HexColor('#8BC34A').withOpacity(0.85),
        'icon': Icons.visibility,
        'angle': 300.0,
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0), 
      child: Row(
        children: [
          // Character on the left
          SizedBox(
            width: 150,
            height: 250,
            child: ModularCharacter(
              armour: armour,
              head: head,
              legs: legs,
              melee: melee,
              arms: arms,
              wings: wings,
            ),
          ),
          const SizedBox(width: 4),
          // Stats on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dynamicStats.map((stat) {
                return _buildStatBar(
                  stat['title'],
                  stat['value'],
                  stat['color'],
                  stat['icon'],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String title, int value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value / 100,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ModularCharacter extends StatelessWidget {
  final String armour;
  final String head;
  final String legs;
  final String melee;
  final String arms;
  final String wings;

  const ModularCharacter({
    super.key,
    required this.armour,
    required this.head,
    required this.legs,
    required this.melee,
    required this.arms,
    required this.wings,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('bodyColorIndex') ?? '3',
      ),
      builder: (context, snapshot) {
        final bodyIndex = snapshot.data ?? '3';
        return Stack(
          alignment: Alignment.center,
          children: [
            if (wings.isNotEmpty)
              Image.asset(
                'assets/character/wings/$wings.png',
                fit: BoxFit.contain,
              ),
            Image.asset(
              'assets/character/base_body_$bodyIndex.png',
              fit: BoxFit.contain,
            ),
            if (armour.isNotEmpty)
              Image.asset(
                'assets/character/armour/$armour.png',
                fit: BoxFit.contain,
              ),
            if (head.isNotEmpty)
              Image.asset(
                'assets/character/heads/$head.png',
                fit: BoxFit.contain,
              ),
            if (legs.isNotEmpty)
              Image.asset(
                'assets/character/legs/$legs.png',
                fit: BoxFit.contain,
              ),
            if (melee.isNotEmpty)
              Image.asset(
                'assets/character/melee/$melee.png',
                fit: BoxFit.contain,
              ),
            if (arms.isNotEmpty)
              Image.asset(
                'assets/character/arm/$arms.png',
                fit: BoxFit.contain,
              ),
          ],
        );
      },
    );
  }
}
