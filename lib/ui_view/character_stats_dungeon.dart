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

  const CharacterStatsView({
    super.key,
    required this.head,
    required this.armour,
    required this.legs,
    required this.melee,
    required this.arms,
    required this.wings,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dynamic stats list using the stats parameter

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0), 
      child: Row(
        children: [
          // Character on the left
           ClipRect(
            child: Align(
              alignment: Alignment.centerRight, // Align to the right to crop the left
              child: SizedBox(
                width: 150, // Desired cropped width
                height: 350,
                child: ModularCharacter(
                  armour: armour,
                  head: head,
                  legs: legs,
                  melee: melee,
                  arms: arms,
                  wings: wings,
                ),
              ),
            ),
          ),
        ]
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
