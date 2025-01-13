// animated_chest.dart

import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedChest extends StatefulWidget {
  final bool open;
  final VoidCallback? onAnimationComplete;
  final VoidCallback? onPreloadError;
  final int chestNumber; // 1: Common, 2: Rare, 3: Epic

  const AnimatedChest({
    Key? key,
    required this.open,
    this.onAnimationComplete,
    this.onPreloadError,
    required this.chestNumber, // Required to determine chest type
  }) : super(key: key);

  @override
  _AnimatedChestState createState() => _AnimatedChestState();

  // Static variables to maintain state across instances and rebuilds
  static bool hasAnimated = false;
  static final Map<String, List<ImageProvider>> preloadedImages = {};
  static final Map<String, bool> hasPreloaded = {};

  // Public static setter for hasAnimated
  static void setHasAnimated(bool value) => hasAnimated = value;
}

class _AnimatedChestState extends State<AnimatedChest>
    with SingleTickerProviderStateMixin {
  late final String chestType; // common, rare, epic
  late final int totalFrames;
  Timer? _timer;

  // Added state variable to track the current frame
  int _currentFrame = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    chestType = _determineChestType(widget.chestNumber);
    totalFrames = _getTotalFrames(chestType);

    if (!(AnimatedChest.hasPreloaded[chestType] ?? false)) {
      _preloadImages();
    } else if (widget.open && !AnimatedChest.hasAnimated) {
      // Only start animation if it hasn't played before
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
    }
  }

  String _determineChestType(int chestNumber) {
    switch (chestNumber) {
      case 1:
        return 'common';
      case 2:
        return 'rare';
      case 3:
        return 'epic';
      default:
        return 'common';
    }
  }

  int _getTotalFrames(String chestType) {
    switch (chestType) {
      case 'common':
        return 4; // common-1.png to common-4.png
      case 'rare':
        return 5; // rare-1.png to rare-5.png
      case 'epic':
        return 10; // epic-1.png to epic-10.png
      default:
        return 4;
    }
  }

  String _getFramePath(int index) {
    // Frame index starts from 1
    return '$chestType/${chestType}-$index.png';
  }

  Future<void> _preloadImages() async {
    if (AnimatedChest.hasPreloaded[chestType] ?? false) {
      return;
    }

    List<String> failedImages = [];

    for (int i = 1; i <= totalFrames; i++) {
      final path = _getFramePath(i);
      final success = await _tryPreloadImage(path);
      if (!success) {
        failedImages.add(path);
      }
    }

    if (mounted) {
      setState(() {
        if (failedImages.isEmpty) {
          AnimatedChest.hasPreloaded[chestType] = true;
          if (widget.open && !AnimatedChest.hasAnimated) {
            _startAnimation();
          }
        } else {
          widget.onPreloadError?.call();
        }
      });
    }
  }

  Future<bool> _tryPreloadImage(String path) async {
    try {
      final image = AssetImage('assets/images/chests/$path');
      final ImageStream stream = image.resolve(ImageConfiguration.empty);

      final completer = Completer<bool>();

      final listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (exception, stackTrace) {
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      stream.addListener(listener);

      // Handle timeout
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      final success = await completer.future;

      // Remove listener to prevent memory leaks
      stream.removeListener(listener);

      if (success) {
        await precacheImage(image, context);
        // Initialize the list for this chestType if not already
        AnimatedChest.preloadedImages.putIfAbsent(chestType, () => []);
        AnimatedChest.preloadedImages[chestType]!.add(image);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _startAnimation() {

    if (AnimatedChest.hasAnimated ||
        !(AnimatedChest.hasPreloaded[chestType] ?? false) ||
        (AnimatedChest.preloadedImages[chestType]?.length ?? 0) < totalFrames) {
      return;
    }

    AnimatedChest.hasAnimated = true; // Mark as animated globally
    setState(() {
      _isAnimating = true;
      _currentFrame = 1; // Start from frame 2 for animation
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      setState(() {
        _currentFrame++;
        if (_currentFrame >= totalFrames) {
          _currentFrame = totalFrames - 1; // Ensure it doesn't exceed
          _isAnimating = false;
          _timer?.cancel();
          widget.onAnimationComplete?.call();
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.open && widget.open && !AnimatedChest.hasAnimated && (AnimatedChest.hasPreloaded[chestType] ?? false)) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(AnimatedChest.hasPreloaded[chestType] ?? false)) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Determine the frame to display
    int frameIndex;
    if (_isAnimating) {
      frameIndex = _currentFrame;
    } else if (AnimatedChest.hasAnimated) {
      frameIndex = totalFrames; // Display the last frame after animation
    } else {
      frameIndex = 1; // Display the first frame if not animating
    }

    // Adjust frameIndex for one-based indexing
    frameIndex = frameIndex.clamp(1, totalFrames);

    return SizedBox(
      width: 200,
      height: 200,
      child: Image.asset(
        'assets/images/chests/${_getFramePath(frameIndex)}',
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.broken_image, size: 48, color: Colors.red[300]);
        },
      ),
    );
  }
}
