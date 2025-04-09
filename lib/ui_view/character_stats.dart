import 'dart:math' as math;
import 'dart:ui'; // Import for PointMode and Offset

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:workout_logger/models.dart'; // Try importing from models.dart

// --- CharacterStatsView Widget --- 

class CharacterStatsView extends StatefulWidget {
  final AnimationController? animationController; // can be nullable
  final Animation<double>? animation; // can be nullable
  final String head;
  final String armor;
  final String legs;
  final String melee;
  final String arms;
  final String wings;
  final String baseBody;
  final String eyeColor;
  final Map<String, dynamic> stats; // Expects keys like 'strength', 'speed', etc.

  const CharacterStatsView({
    super.key,
    this.animationController,
    this.animation,
    required this.head,
    required this.armor,
    required this.legs,
    required this.melee,
    required this.arms,
    required this.wings,
    required this.baseBody,
    required this.eyeColor,
    required this.stats,
  });

  @override
  _CharacterStatsViewState createState() => _CharacterStatsViewState();
}

// --- _CharacterStatsViewState --- 

class _CharacterStatsViewState extends State<CharacterStatsView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin { // Add AutomaticKeepAliveClientMixin
  
  // --- Constants --- 
  static const double characterSize = 250.0; 
  static const Size statBoxSize = Size(100, 100); 
  static const Map<String, Offset> statPositions = {
      'VIS': Offset(-characterSize * 0.5, -characterSize * 0.6), 
      'INT': Offset(characterSize * 0.5, -characterSize * 0.6), 
      'STR': Offset(-characterSize * 0.5, -characterSize * 0.1), 
      'END': Offset(characterSize * 0.5, -characterSize * 0.1), 
      'SPD': Offset(-characterSize * 0.5, characterSize * 0.45),
      'AGI': Offset(characterSize * 0.5, characterSize * 0.45), 
  };
  static const Color _accentColor = Color(0xFFADFF2F);
  static const Color _lineColor = Colors.grey;

  // --- Animation Controllers & Animations --- 
  late AnimationController _lineAnimationController;
  late Animation<double> _lineAnimation;
  late AnimationController _flickerAnimationController;
  late Animation<double> _flickerAnimation;

  // --- State Flags --- 
  bool _linesComplete = false; // Flag to track line animation completion
  bool _characterLanded = false; // Flag to track when character has landed

  // --- Lifecycle Methods --- 
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    // Remove listener if parent controller exists (although listener logic is currently empty)
    if (widget.animationController != null) {
       widget.animationController!.removeListener(_handleParentAnimation);
    }
    _lineAnimationController.dispose();
    _flickerAnimationController.dispose(); 
    super.dispose();
  }

  // --- Initialization --- 
  void _initializeAnimations() {
    // Line Animation
    _lineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), 
    );
    _lineAnimation = CurvedAnimation(
      parent: _lineAnimationController,
      curve: Curves.easeInOut,
    );
    _lineAnimationController.addStatusListener(_onLineAnimationStatusChanged);

    // Flicker/Fade-in Animation
    _flickerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), 
    );
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 40),
    ]).animate(_flickerAnimationController);

    // Add listener to parent animation controller if it exists (currently unused)
    if (widget.animationController != null) {
       widget.animationController!.addListener(_handleParentAnimation);
    }
  }

  // --- Animation Callbacks & Handlers --- 

  // Called when the ModularCharacter's landing animation completes
  void _onCharacterLanded() {
    if (mounted) {
      setState(() {
        _characterLanded = true;
      });
      // Start line animation after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_lineAnimationController.isAnimating && !_lineAnimationController.isCompleted) {
          _lineAnimationController.forward();
        }
      });
    }
  }

  // Called when the line drawing animation completes
  void _onLineAnimationStatusChanged(AnimationStatus status) {
     if (status == AnimationStatus.completed) {
        if (mounted) { 
          setState(() {
             _linesComplete = true;
          });
          // Start flicker animation after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_flickerAnimationController.isAnimating && !_flickerAnimationController.isCompleted) {
              _flickerAnimationController.forward(from: 0.0); 
            }
          });
        }
      }
  }

  // Listener for parent animation controller (currently does nothing)
  void _handleParentAnimation() {
    // If needed, react to parent animation controller changes here
    // e.g., start animations based on parent controller's value
  }

  // --- Helper Functions --- 

  // Maps raw stats to displayable data (label, value, icon)
  Map<String, Map<String, dynamic>> _getStatData() {
    return {
      'VIS': {
        'value': widget.stats['stealth']?.toString() ?? '0', 
        'icon': Icons.remove_red_eye,
      },
      'STR': {
        'value': widget.stats['strength']?.toString() ?? '0',
        'icon': Icons.fitness_center,
      },
      'INT': {
        'value': widget.stats['intelligence']?.toString() ?? '0',
        'icon': Icons.lightbulb, 
      },
      'SPD': {
        'value': widget.stats['speed']?.toString() ?? '0',
        'icon': Icons.flash_on, 
      },
      'END': {
        'value': widget.stats['defence']?.toString() ?? '0',
        'icon': Icons.shield, 
      },
      'AGI': {
        'value': widget.stats['defence']?.toString() ?? '0',
        'icon': Icons.shield, 
      },
    };
  }

  // --- Build Methods --- 

  @override
  bool get wantKeepAlive => true; // Keep the state alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super.build for AutomaticKeepAliveClientMixin

    final statData = _getStatData();
    // Use parent animation if available, otherwise a completed animation
    final parentAnimation = widget.animationController?.drive(CurveTween(curve: Curves.easeOut))
                          ?? const AlwaysStoppedAnimation(1.0);

    // Calculate required stack size dynamically
    double maxX = 0, maxY = 0;
    statPositions.forEach((key, offset) {
        maxX = math.max(maxX, offset.dx.abs() + statBoxSize.width / 2);
        maxY = math.max(maxY, offset.dy.abs() + statBoxSize.height / 2);
    });
    final double stackWidth = math.max(characterSize, maxX * 2) + 20; // Add padding
    final double stackHeight = math.max(characterSize * 1.5, maxY * 2) + 20; // Add padding

    return AnimatedBuilder(
      animation: parentAnimation, // Listen to parent animation for overall fade/slide
      builder: (context, child) {
        return FadeTransition(
          opacity: parentAnimation, // Use parent animation for fade
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - parentAnimation.value), // Slide in effect
              0.0,
            ),
            child: Center(
              child: SizedBox(
                width: stackWidth,
                height: stackHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Character (Handles its own falling animation)
                    SizedBox(
                      width: characterSize* 2,
                      height: characterSize * 2, 
                      child: ModularCharacter(
                        armor: widget.armor,
                        head: widget.head,
                        legs: widget.legs,
                        melee: widget.melee,
                        arms: widget.arms,
                        wings: widget.wings,
                        baseBody: widget.baseBody,
                        eyeColor: widget.eyeColor,
                        onLandingCompleted: _onCharacterLanded, // Callback when character lands
                      ),
                    ),

                    // Connector Lines (Appear after character lands)
                    if (_characterLanded)
                      Positioned.fill(
                        child: AnimatedBuilder( 
                          animation: _lineAnimation,
                          builder: (context, _) {
                             return CustomPaint(
                                painter: StatsConnectorPainter(
                                  statPositions: statPositions,
                                  statBoxSize: statBoxSize,
                                  lineColor: _lineColor,
                                  progress: _lineAnimation.value,
                                  characterSize: characterSize,
                                ),
                             );
                          },
                        ),
                      ),

                    // Stat Boxes (Appear after lines are drawn)
                    if (_characterLanded && _linesComplete)
                      ..._buildStatWidgets(statData, stackWidth, stackHeight),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Builds the list of positioned stat widgets
  List<Widget> _buildStatWidgets(Map<String, Map<String, dynamic>> statData, double stackWidth, double stackHeight) {
    return statData.entries.map((entry) {
      String key = entry.key;
      Map<String, dynamic> data = entry.value;
      Offset pos = statPositions[key]!;
      // Calculate position relative to stack center
      double left = (stackWidth / 2) + pos.dx - (statBoxSize.width / 2);
      double top = (stackHeight / 2) + pos.dy - (statBoxSize.height / 2);

      return Positioned(
        left: left,
        top: top,
        width: statBoxSize.width,
        height: statBoxSize.height,
        child: AnimatedBuilder(
          animation: _flickerAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _flickerAnimation.value, // Use animation value for opacity
              child: child,
            );
          },
          child: _buildSingleStatWidget(
            key, // Label (e.g., 'STR')
            data['value'], // Value (e.g., '10')
            _accentColor,
            data['icon'], // Icon
          ),
        ),
      );
    }).toList();
  }

  // Builds the visual representation of a single stat box
  Widget _buildSingleStatWidget(String label, String value, Color color, IconData icon) {
     return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/stat_frame.png'),
          fit: BoxFit.fill, 
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 24.0), 
            const SizedBox(height: 4.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
               textBaseline: TextBaseline.alphabetic,
              children: [
                 Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 const SizedBox(width: 4),
                 Text(
                   label, 
                   style: TextStyle(
                     color: Colors.grey[400],
                     fontSize: 12.0, 
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ]
            ),
          ],
        ),
      ),
    );
  }
}

// --- StatsConnectorPainter --- 

class StatsConnectorPainter extends CustomPainter {
  final Map<String, Offset> statPositions;
  final Size statBoxSize; 
  final Color lineColor;
  final double progress; // Animation progress (0.0 to 1.0)
  final double characterSize; // Add character size parameter

  StatsConnectorPainter({
    required this.statPositions,
    required this.statBoxSize,
    required this.lineColor,
    required this.progress,
    required this.characterSize, // Add to constructor parameters
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return; // Don't paint if progress is 0

    final paint = Paint()
      ..color = lineColor.withOpacity(math.max(0, progress * 2 - 1)) // Fade in
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

     final glowPaint = Paint() // Glow effect
      ..color = _CharacterStatsViewState._accentColor.withOpacity(0.3 * math.max(0, progress * 2 - 1)) // Fade in glow
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final Offset center = Offset(size.width / 2, size.height / 2);
    // Define head position (slightly above center)
    final Offset headPosition = Offset(center.dx, center.dy - characterSize * 0.54); // 60/250 = 0.24
    final Offset eyePosition = Offset(center.dx, center.dy - characterSize * 0.45); // 60/250 = 0.24
    final Offset chestPosition = Offset(center.dx + characterSize * 0.05, center.dy - characterSize * 0.23);
    final Offset bicepPosition = Offset(center.dx- characterSize * 0.17, center.dy - characterSize * 0.19);
    final Offset thighPosition = Offset(center.dx + characterSize * 0.1, center.dy + characterSize * 0.24); // 90/250 = 0.36
    final Offset legPosition = Offset(center.dx - characterSize * 0.12, center.dy + characterSize * 0.42); // 90/250 = 0.36


    for (final MapEntry<String, Offset> entry in statPositions.entries) {
      final String statKey = entry.key;
      final Offset relativePos = entry.value; // Position relative to character center
      final Offset absolutePos = center + relativePos; // Position relative to stack top-left
      
      // Use head position as starting point for top stats (VIS and STR)
      Offset startOffset;
      if (statKey == 'VIS') {
        startOffset = eyePosition;
      } else if (statKey == 'STR') {
        startOffset = bicepPosition;
      } else if (statKey == 'END') {
        startOffset = chestPosition;
      } else if (statKey == 'AGI') {
        startOffset = thighPosition;
      } else if (statKey == 'SPD'){
        startOffset = legPosition;
      } else if (statKey == 'INT') {
        startOffset = headPosition;
      } else {
        startOffset = center;
      }


      
      // Calculate the center of the stat box (relative to stack top-left)
      Offset statCenterPoint = absolutePos;
      // Define the target point on the character body
      Offset targetEndPoint = startOffset;

      // Determine the midpoint of the stat box side closest to the targetEndPoint
      double dxToTarget = targetEndPoint.dx - statCenterPoint.dx;
      double dyToTarget = targetEndPoint.dy - statCenterPoint.dy;
      double halfWidth = statBoxSize.width / 2;
      double halfHeight = statBoxSize.height / 2;
      double startXOffset, startYOffset;

      if (dxToTarget.abs() * halfHeight > dyToTarget.abs() * halfWidth) {
          // Closest side is Left or Right
          startXOffset = dxToTarget.sign * 0.8 * halfWidth ;
          startYOffset = 0; // Midpoint vertically
      } else if (dyToTarget.abs() * halfWidth > dxToTarget.abs() * halfHeight) {
          // Closest side is Top or Bottom
          startXOffset = 0; // Midpoint horizontally
          startYOffset = dyToTarget.sign * halfHeight;
      } else {
          // Edge case: Exactly on the corner diagonal - pick one (e.g., vertical)
          startXOffset = dxToTarget.sign * halfWidth;
          startYOffset = 0;
      }
      Offset startPoint = statCenterPoint + Offset(startXOffset, startYOffset);

      // Define start and end points for the animated line segment
      // Reverse direction: start from stat side midpoint, end at character body part
      // startPoint is already calculated above
      // targetEndPoint is already defined as startOffset
 
      // Calculate the corner point for the two-segment line
      Offset cornerPoint; 
      double deltaX = targetEndPoint.dx - startPoint.dx;
      // Use a fixed factor for the break point, can be adjusted
      double factor = 0.6; // Adjust corner point for better appearance
      
      // Create an angled path first, then horizontal
      // First go at an angle until reaching the target's vertical height
      cornerPoint = Offset(
        startPoint.dx + (targetEndPoint.dx - startPoint.dx) * 0.5, // Halfway horizontally
        targetEndPoint.dy
      );

      // Animate the line drawing in two segments based on progress
      Path path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      // Animate first segment (start point to corner)
      double progressSegment1 = (progress * 2).clamp(0.0, 1.0); 
      Offset animatedPoint1 = progressSegment1 < 1.0 ? 
          Offset.lerp(startPoint, cornerPoint, progressSegment1)! : cornerPoint;
      path.lineTo(animatedPoint1.dx, animatedPoint1.dy);

      // Animate second segment (corner to target end) if first segment is complete
      if (progress > 0.5) {
        double progressSegment2 = ((progress - 0.5) * 2).clamp(0.0, 1.0); 
        Offset animatedPoint2 = progressSegment2 < 1.0 ? 
            Offset.lerp(cornerPoint, targetEndPoint, progressSegment2)! : targetEndPoint;
        path.lineTo(animatedPoint2.dx, animatedPoint2.dy);
      }
      
      // Draw the animated path with main paint and glow
      canvas.drawPath(path, paint);
      canvas.drawPath(path, glowPaint); 
    }
  }

  @override
  bool shouldRepaint(covariant StatsConnectorPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.statPositions != statPositions ||
      oldDelegate.lineColor != lineColor;
}

// --- ModularCharacter Widget --- 

class ModularCharacter extends StatefulWidget {
  final String armor;
  final String head;
  final String legs;
  final String melee;
  final String arms;
  final String wings;
  final String baseBody;
  final String eyeColor;
  final VoidCallback onLandingCompleted; // Callback for when landing completes

  const ModularCharacter({
    super.key,
    required this.armor,
    required this.head,
    required this.legs,
    required this.melee,
    required this.arms,
    required this.wings,
    required this.baseBody,
    required this.eyeColor,
    required this.onLandingCompleted,
  });

  @override
  State<ModularCharacter> createState() => _ModularCharacterState();
}

// --- _ModularCharacterState --- 

class _ModularCharacterState extends State<ModularCharacter> with TickerProviderStateMixin { // Use TickerProviderStateMixin
  
  // --- Constants --- 
  static const int _totalFallFrames = 5;
  static const int _totalIdleFrames = 20; // Assume 4 idle frames (frame_0 to frame_3)

  // --- Animation Controllers & Animations --- 
  late AnimationController _fallAnimationController;
  late Animation<double> _positionAnimation;
  late AnimationController _idleAnimationController;
  late Animation<int> _idleFrameAnimation; 

  // --- State --- 
  bool _showCharacter = false;
  int _currentFallFrame = 0;

  // --- Lifecycle Methods --- 
  @override
  void initState() {
    super.initState();
    _initializeFallAnimation();
    _initializeIdleAnimation(); // Initialize idle animation
    _fallAnimationController.forward(); // Start falling immediately
  }

  @override
  void dispose() {
    _fallAnimationController.dispose();
    _idleAnimationController.dispose(); // Dispose idle controller
    super.dispose();
  }

  // --- Initialization --- 
  void _initializeFallAnimation(){
    _fallAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Faster fall (e.g., 600ms)
    );

    // Vertical position animation (top to center)
    _positionAnimation = Tween<double>(
      begin: -200.0, // Start above center
      end: 0.0,      // End at center
    ).animate(
      CurvedAnimation(
        parent: _fallAnimationController,
        curve: Curves.linear, // Smooth fall
      ),
    );

    // Update fall frame based on controller value
    _fallAnimationController.addListener(() {
      if (!mounted) return;
      final frameIndex = (_fallAnimationController.value * _totalFallFrames).floor();
      if (frameIndex != _currentFallFrame && frameIndex < _totalFallFrames) {
        setState(() {
          _currentFallFrame = frameIndex;
        });
      }
    });

    // Handle animation completion
    _fallAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _showCharacter = true;
          });
          widget.onLandingCompleted(); // Notify parent
          _idleAnimationController.repeat(); // Start looping idle animation
        }
      }
    });
  }

  // Initialize Idle Animation
  void _initializeIdleAnimation() {
    _idleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Adjust idle loop speed
    );
    _idleFrameAnimation = IntTween(begin: 0, end: _totalIdleFrames - 1)
        .animate(_idleAnimationController);
  }

  // --- Build Methods --- 
  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder for the position animation
    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _positionAnimation.value), // Apply vertical offset
          child: _showCharacter 
              ? _buildLandedCharacter() // Show full character after landing
              : _buildFallingFrame(), // Show current falling frame
        );
      },
    );
  }

  // Builds the image for the current falling frame
  Widget _buildFallingFrame() {
      return Image.asset(
        'assets/images/character/fall/frame$_currentFallFrame.png',
        fit: BoxFit.contain,
        gaplessPlayback: true, // Helps reduce flicker between frames
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
      );
  }

  // Builds the stack of character layers once landed - NOW PLAYS IDLE ANIMATION
  Widget _buildLandedCharacter() {
    return AnimatedBuilder(
      animation: _idleFrameAnimation,
      builder: (context, child) {
        return Image.asset(
          // Assumes idle frames are named frame_0.png, frame_1.png etc.
          'assets/images/character/idle/frame${_idleFrameAnimation.value}.png',
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to base body if idle frames are missing
            print('Error loading idle frame: assets/character/idle/frame${_idleFrameAnimation.value}.png');
            print(error);
            return _buildCharacterLayer('assets/character/base_body_2.png', isCritical: true);
          },
        );
      },
    );
  }

  // Helper to build a single image layer for the character stack
  Widget _buildCharacterLayer(String assetPath, {bool isCritical = false}) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      gaplessPlayback: true, // Helps reduce flicker when layers might change
      errorBuilder: (context, error, stackTrace) {
        // Show an error icon for critical layers (like base body), otherwise hide
        return isCritical ? const Icon(Icons.error, color: Colors.red) : Container();
      },
    );
  }
}


