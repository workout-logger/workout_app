import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import '../fitness_app_theme.dart';

class CharacterStatsView extends StatefulWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final String head;
  final String armor;
  final String legs;
  final String melee;
  final String shield;
  final String wings;

  const CharacterStatsView({
    super.key,
    this.animationController,
    this.animation,
    required this.head,
    required this.armor, 
    required this.legs,
    required this.melee,
    required this.shield,
    required this.wings,
  });

  @override
  _CharacterStatsViewState createState() => _CharacterStatsViewState();
}

class _CharacterStatsViewState extends State<CharacterStatsView> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - widget.animation!.value), 0.0),
                  child: Center(
                    child: SizedBox(
                      width: 400,
                      height: 400,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Character in the center
                          ScaleTransition(
                            scale: widget.animation!,
                            child: SizedBox(
                              width: 180,
                              height: 180,
                              child: ModularCharacter(
                                armor: widget.armor,
                                head: widget.head,
                                legs: widget.legs,
                                melee: widget.melee,
                                shield: widget.shield,
                                wings: widget.wings,
                              ),
                            ),
                          ),
                    // Top Stat
                    Positioned(
                      top: 40,
                      child: _buildCircularStat(
                        'HP',
                        '100',
                        HexColor('#FF6B78'),
                        Icons.favorite,
                      ),
                    ),
                    // Bottom Stat
                    Positioned(
                      bottom: 10,
                      child: _buildCircularStat(
                        'SPD',
                        '90',
                        HexColor('#738AE6'),
                        Icons.flash_on,
                      ),
                    ),
                    // Bottom Left Stat
                    Positioned(
                      left: 50,
                      bottom: 60,
                      child: _buildCircularStat(
                        'AGI',
                        '80',
                        HexColor('#87A0E5'),
                        Icons.directions_walk,
                      ),
                    ),
                    // Bottom Right Stat
                    Positioned(
                      right: 50,
                      bottom: 60,
                      child: _buildCircularStat(
                        'DEF',
                        '70',
                        HexColor('#FFA726'),
                        Icons.shield,
                      ),
                    ),
                    // Top Left Stat
                    Positioned(
                      top: 110,
                      left: 50,
                      child: _buildCircularStat(
                        'INT',
                        '75',
                        HexColor('#FE95B6'),
                        Icons.lightbulb_outline,
                      ),
                    ),
                    // Top Right Stat
                    Positioned(
                      top: 110,
                      right: 50,
                      child: _buildCircularStat(
                        'ATK',
                        '65',
                        HexColor('#8BC34A'),
                        Icons.lightbulb_outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    },
  );
}

  // Widget for the circular stat
  Widget _buildCircularStat(String title, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
class ModularCharacter extends StatelessWidget {
  final String armor;
  final String head;
  final String legs;
  final String melee;
  final String shield;
  final String wings;

  const ModularCharacter({
    super.key,
    required this.armor,
    required this.head,
    required this.legs,
    required this.melee,
    required this.shield,
    required this.wings,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (wings.isNotEmpty)
          Image.asset(
            'assets/character/wings/$wings',
            fit: BoxFit.contain,
          ),
        if (armor.isNotEmpty)
          Image.asset(
            'assets/character/armour/$armor',
            fit: BoxFit.contain,
          ),
        if (head.isNotEmpty)
          Image.asset(
            'assets/character/heads/$head',
            fit: BoxFit.contain,
          ),
        if (legs.isNotEmpty)
          Image.asset(
            'assets/character/legs/$legs',
            fit: BoxFit.contain,
          ),
        if (melee.isNotEmpty)
          Image.asset(
            'assets/character/melee/$melee',
            fit: BoxFit.contain,
          ),
      ],
    );
  }
}
