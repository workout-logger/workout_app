import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
// import '../fitness_app_theme.dart'; // Remove or adjust to your needs
import 'package:shared_preferences/shared_preferences.dart';

class CharacterStatsView extends StatefulWidget {
  final AnimationController? animationController; // can be nullable
  final Animation<double>? animation; // can be nullable
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
  // Rotation controller to spin the stats around the character
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;


  // Tracks each stat’s final scale factor for a “fade in” effect
  final List<double> _statValues = List.filled(6, 0.0);

  bool _isInitialized = false;

  final List<Map<String, dynamic>> stats = [
    {
      'title': 'HP',
      'value': '100',
      'color': HexColor('#FF6B78').withOpacity(0.85),
      'icon': Icons.favorite,
      'angle': 0.0,
    },
    {
      'title': 'SPD',
      'value': '90',
      'color': HexColor('#738AE6').withOpacity(0.85),
      'icon': Icons.flash_on,
      'angle': 60.0,
    },
    {
      'title': 'AGI',
      'value': '80',
      'color': HexColor('#87A0E5').withOpacity(0.85),
      'icon': Icons.directions_walk,
      'angle': 120.0,
    },
    {
      'title': 'DEF',
      'value': '70',
      'color': HexColor('#FFA726').withOpacity(0.85),
      'icon': Icons.shield,
      'angle': 180.0,
    },
    {
      'title': 'INT',
      'value': '75',
      'color': HexColor('#FE95B6').withOpacity(0.85),
      'icon': Icons.lightbulb_outline,
      'angle': 240.0,
    },
    {
      'title': 'ATK',
      'value': '65',
      'color': HexColor('#8BC34A').withOpacity(0.85),
      'icon': Icons.flash_auto,
      'angle': 300.0,
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1) ROTATION CONTROLLER
    _rotationController = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this, // <-- TickerProviderStateMixin
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    );
    _rotationController.repeat();


    // Animate stats in once
    if (!_isInitialized) {
      _animateStatsSequentially();
    }
  }

  void _animateStatsSequentially() {
    _isInitialized = true;
    for (var i = 0; i < stats.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + (i * 150)), () {
        if (mounted) {
          setState(() {
            _statValues[i] = 1.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Adjusts the visibility of stat widgets based on angle.
  double _calculateVisibility(double angle) {
    const double fadeStart = pi;
    const double fadeEnd = pi * 2;

    // Normalize the angle between 0 and 2 * pi
    angle %= 2 * pi;

    if (angle > fadeStart && angle < fadeEnd) {
      double normalizedAngle = (angle - fadeStart) / (fadeEnd - fadeStart);
      double sinValue = sin(normalizedAngle * pi);
      // scale from ~0.3 to 1.0
      return 0.3 + (0.7 * (1 - sinValue));
    }
    return 1.0; // fully visible
  }

  /// Adjusts the scale of stat widgets based on angle.
  double _calculateScale(double angle) {
    const double fadeStart = pi;
    const double fadeEnd = pi * 2;

    // Normalize angle between 0 and 2 * pi
    angle %= 2 * pi;

    if (angle > fadeStart && angle < fadeEnd) {
      double normalizedAngle = (angle - fadeStart) / (fadeEnd - fadeStart);
      double sinValue = sin(normalizedAngle * pi);
      return 0.8 + (0.2 * (1 - sinValue));
    }
    return 1.0; 
  }

  @override
  Widget build(BuildContext context) {
    // Safely merge controllers
    // Include the external controller if it's not null
    final controllers = [
      _rotationController,
      if (widget.animationController != null) widget.animationController!,
    ];

    // If you have a non-null widget.animation, you can fade or scale with it
    final fadeAnimation = widget.animation ?? const AlwaysStoppedAnimation(1.0);
    
    return AnimatedBuilder(
      animation: Listenable.merge(controllers),
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - fadeAnimation.value),
              0.0,
            ),
            child: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Character with a subtle "breathing" effect
                    SizedBox(
                      child: ModularCharacter(
                        armor: widget.armor,
                        head: widget.head,
                        legs: widget.legs,
                        melee: widget.melee,
                        shield: widget.shield,
                        wings: widget.wings,
                      ),
                    ),

                   

                    // Rotating stats
                    ...List.generate(stats.length, (index) {
                      final baseAngle = (stats[index]['angle'] as double) * pi / 180.0;
                      final currentAngle = baseAngle + (_rotationAnimation.value * 2 * pi);

                      final radius = 160.0 * _statValues[index];
                      final x = radius * cos(currentAngle);
                      final y = radius * sin(currentAngle);

                      final visibility = _calculateVisibility(currentAngle);
                      final scale = _calculateScale(currentAngle);

                      return Transform.translate(
                        offset: Offset(x, y),
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: visibility * _statValues[index],
                            child: _buildStatWidget(
                              stats[index]['title'],
                              stats[index]['value'],
                              stats[index]['color'],
                              stats[index]['icon'],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatWidget(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color.withOpacity(0.9), size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Example of the ModularCharacter widget
class ModularCharacter extends StatefulWidget {
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
  State<ModularCharacter> createState() => _ModularCharacterState();
}

class _ModularCharacterState extends State<ModularCharacter> {
  String baseBody = '4'; // Default base body
  String eyeColor = '4'; // Default eye color

  @override
  void initState() {
    super.initState();
    _loadCharacterAttributes();
  }

  Future<void> _loadCharacterAttributes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Retrieve attributes from SharedPreferences or use defaults
      baseBody = prefs.getString('body_color_index') ?? '4';
      eyeColor = prefs.getString('eye_color_index') ?? '4';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.wings.isNotEmpty)
          Image.asset(
            'assets/character/wings/${widget.wings}.png',
            fit: BoxFit.contain,
          ),
        Image.asset(
          'assets/character/base_body_$baseBody.png',
          fit: BoxFit.contain,
        ),
        Image.asset(
          'assets/character/eye_color_$eyeColor.png',
          fit: BoxFit.contain,
        ),
        if (widget.armor.isNotEmpty)
          Image.asset(
            'assets/character/armour/${widget.armor}.png',
            fit: BoxFit.contain,
          ),
        if (widget.head.isNotEmpty)
          Image.asset(
            'assets/character/heads/${widget.head}.png',
            fit: BoxFit.contain,
          ),
        if (widget.legs.isNotEmpty)
          Image.asset(
            'assets/character/legs/${widget.legs}.png',
            fit: BoxFit.contain,
          ),
        if (widget.melee.isNotEmpty)
          Image.asset(
            'assets/character/melee/${widget.melee}.png',
            fit: BoxFit.contain,
          ),
        if (widget.shield.isNotEmpty)
          Image.asset(
            'assets/character/shield/${widget.shield}.png',
            fit: BoxFit.contain,
          ),
      ],
    );
  }
}
