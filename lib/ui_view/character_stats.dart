import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import '../fitness_app_theme.dart';

class CharacterStatsView extends StatefulWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;

  const CharacterStatsView({
    super.key,
    this.animationController,
    this.animation,
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
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: FitnessAppTheme.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                    topRight: Radius.circular(68.0),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: FitnessAppTheme.grey.withOpacity(0.2),
                      offset: const Offset(1.1, 1.1),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Left Column with 3 stats
                      Flexible(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _buildAnimatedStat(
                              'Strength',
                              '75',
                              HexColor('#FF6B78'),
                              Icons.fitness_center,
                              widget.animationController!,
                            ),
                            const SizedBox(height: 12),
                            _buildAnimatedStat(
                              'Endurance',
                              '82',
                              HexColor('#738AE6'),
                              Icons.timer,
                              widget.animationController!,
                            ),
                            const SizedBox(height: 12),
                            _buildAnimatedStat(
                              'Stamina',
                              '65',
                              HexColor('#FE95B6'),
                              Icons.directions_run,
                              widget.animationController!,
                            ),
                          ],
                        ),
                      ),
                      // Center Column with character idle sprite 0
                      ScaleTransition(
                        scale: widget.animation!,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                              width: 180,
                              height: 180,
                              child: Image.asset(
                                'assets/images/sprite_idle0.png',
                                fit: BoxFit.contain,
                                width: 180,
                                height: 180,
                                alignment: Alignment.bottomCenter,
                              ),
                            ),
                        ),
                      ),
                      // Right Column with 3 stats
                      Flexible(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _buildAnimatedStat(
                              'Agility',
                              '72',
                              HexColor('#87A0E5'),
                              Icons.directions_walk,
                              widget.animationController!,
                            ),
                            const SizedBox(height: 12),
                            _buildAnimatedStat(
                              'Intelligence',
                              '90',
                              HexColor('#FFA726'),
                              Icons.lightbulb_outline,
                              widget.animationController!,
                            ),
                            const SizedBox(height: 12),
                            _buildAnimatedStat(
                              'Luck',
                              '50',
                              HexColor('#8BC34A'),
                              Icons.casino,
                              widget.animationController!,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Animated stat builder with scale animation
  Widget _buildAnimatedStat(
    String title,
    String value,
    Color color,
    IconData icon,
    AnimationController animationController,
  ) {
    final scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
      ),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: FitnessAppTheme.fontName,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: FitnessAppTheme.grey.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: FitnessAppTheme.fontName,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: FitnessAppTheme.darkerText,
            ),
          ),
        ],
      ),
    );
  }
}
