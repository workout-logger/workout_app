import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CharacterStatsView extends StatelessWidget {
  final String head;
  final String armour;
  final String legs;
  final String melee;
  final String shield;
  final String wings;

  // List of stats with their properties
  final List<Map<String, dynamic>> stats = [
    {
      'title': 'HP',
      'value': 100,
      'color': HexColor('#FF6B78'),
      'icon': Icons.favorite,
    },
    {
      'title': 'SPD',
      'value': 90,
      'color': HexColor('#738AE6'),
      'icon': Icons.flash_on,
    },
    {
      'title': 'AGI',
      'value': 80,
      'color': HexColor('#87A0E5'),
      'icon': Icons.directions_walk,
    },
    {
      'title': 'DEF',
      'value': 70,
      'color': HexColor('#FFA726'),
      'icon': Icons.shield,
    },
    {
      'title': 'INT',
      'value': 75,
      'color': HexColor('#FE95B6'),
      'icon': Icons.lightbulb_outline,
    },
    {
      'title': 'ATK',
      'value': 65,
      'color': HexColor('#8BC34A'),
      'icon': Icons.whatshot,
    },
  ];

  CharacterStatsView({
    super.key,
    required this.head,
    required this.armour,
    required this.legs,
    required this.melee,
    required this.shield,
    required this.wings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              shield: shield,
              wings: wings,
            ),
          ),
          const SizedBox(width: 4),
          // Stats on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stats.map((stat) {
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
  final String shield;
  final String wings;

  const ModularCharacter({
    super.key,
    required this.armour,
    required this.head,
    required this.legs,
    required this.melee,
    required this.shield,
    required this.wings,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SharedPreferences.getInstance().then((prefs) => 
        prefs.getString('bodyColorIndex') ?? '3'),
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
            if (shield.isNotEmpty)
              Image.asset(
                'assets/character/shield/$shield.png',
                fit: BoxFit.contain,
              ),
          ],
        );
      }
    );
  }
}
