import 'dart:math'; // Import this to use math functions like sin and cos
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

class _CharacterStatsViewState extends State<CharacterStatsView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // List of stats with their properties and initial angles
  final List<Map<String, dynamic>> stats = [
    {
      'title': 'HP',
      'value': '100',
      'color': HexColor('#FF6B78'),
      'icon': Icons.favorite,
      'angle': 0.0,
    },
    {
      'title': 'SPD',
      'value': '90',
      'color': HexColor('#738AE6'),
      'icon': Icons.flash_on,
      'angle': 60.0,
    },
    {
      'title': 'AGI',
      'value': '80',
      'color': HexColor('#87A0E5'),
      'icon': Icons.directions_walk,
      'angle': 120.0,
    },
    {
      'title': 'DEF',
      'value': '70',
      'color': HexColor('#FFA726'),
      'icon': Icons.shield,
      'angle': 180.0,
    },
    {
      'title': 'INT',
      'value': '75',
      'color': HexColor('#FE95B6'),
      'icon': Icons.lightbulb_outline,
      'angle': 240.0,
    },
    {
      'title': 'ATK',
      'value': '65',
      'color': HexColor('#8BC34A'),
      'icon': Icons.lightbulb_outline,
      'angle': 300.0,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize the rotation controller and animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30), // Duration for a full rotation
      vsync: this,
    )..repeat(); // Repeat the animation indefinitely

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_rotationController);
  }

  @override
  void dispose() {
    _rotationController.dispose(); // Dispose the controller when not in use
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animationController!, _rotationController]),
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.animation!,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - widget.animation!.value),
              0.0,
            ),
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
                    // Spinning stats
                    ...stats.map((stat) {
                      // Calculate the current angle for each stat
                      double angle = (stat['angle'] as double) * pi / 180.0 + _rotationAnimation.value;
                      double radius = 130.0; // Distance from the center

                      // Calculate x and y positions
                      double x = radius * cos(angle);
                      double y = radius * sin(angle);

                      return Transform.translate(
                        offset: Offset(x, y),
                        child: _buildCircularStat(
                          stat['title'],
                          stat['value'],
                          stat['color'],
                          stat['icon'],
                        ),
                      );
                    }).toList(),
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
  Widget _buildCircularStat(
      String title, String value, Color color, IconData icon) {
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
