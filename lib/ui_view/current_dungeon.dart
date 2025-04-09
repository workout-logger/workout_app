import 'package:flutter/material.dart';

class CurrentDungeonView extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final double distanceRun; // Example: 23.0
  final String recentEvent; // Example: "Killed a Goblin!"
  final double currentHealth; // Example: 75.0
  final double maxHealth; // Example: 100.0

  const CurrentDungeonView({
    super.key,
    this.animationController,
    this.animation,
    this.distanceRun = 0.0,
    this.recentEvent = "No recent events",
    this.currentHealth = 100.0,
    this.maxHealth = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFADFF2F);
    const Color textColorPrimary = Colors.white;
    const Color textColorSecondary = Colors.grey;
    final double healthPercentage = maxHealth > 0 ? (currentHealth / maxHealth) : 0;

    // Using AnimatedBuilder if animations are needed, otherwise a simple Column
    // For now, let's skip the animation part for simplicity
    // return AnimatedBuilder(...) 
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: <Widget>[
          // Top Row: Distance Run & Recent Event
          Row(
            children: <Widget>[
              // Distance Run Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distance Run',
                        style: TextStyle(color: textColorSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${distanceRun.toStringAsFixed(1)} Km', // Format to 1 decimal place
                        style: const TextStyle(
                          color: textColorPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Placeholder for runner image/animation
                      Container(
                        height: 50, 
                        alignment: Alignment.center,
                        child: const Icon(Icons.directions_run, color: accentColor, size: 30), // Placeholder icon
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Recent Event Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Event',
                        style: TextStyle(color: textColorSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recentEvent,
                        style: const TextStyle(
                          color: textColorPrimary,
                          fontSize: 16, // Slightly smaller than distance
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                       const SizedBox(height: 8),
                      // Placeholder for event image/animation (e.g., goblin parts)
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: const Row( // Placeholder icons
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                             Icon(Icons.shield, color: accentColor, size: 20), 
                             Icon(Icons.star, color: accentColor, size: 20), 
                          ],
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom Row: Health Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: Colors.grey.shade900,
               borderRadius: BorderRadius.circular(8),
             ),
            child: Row(
              children: <Widget>[
                const Text(
                  'Health:',
                  style: TextStyle(color: textColorSecondary, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: LinearProgressIndicator(
                      value: healthPercentage,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                 Text(
                   '${currentHealth.toInt()}/${maxHealth.toInt()}',
                   style: const TextStyle(color: textColorPrimary, fontSize: 14),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 