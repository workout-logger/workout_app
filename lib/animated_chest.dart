import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedChest extends StatefulWidget {
  final bool open;
  final VoidCallback? onAnimationComplete;
  final VoidCallback? onPreloadError;
  final String basePath;

  const AnimatedChest({
    Key? key,
    required this.open,
    this.onAnimationComplete,
    this.onPreloadError,
    this.basePath = 'assets/images/chests',
  }) : super(key: key);

  @override
  _AnimatedChestState createState() => _AnimatedChestState();

  // Static variables to maintain state across instances and rebuilds
  static bool hasPreloaded = false;
  static bool hasAnimated = false;
  static final List<ImageProvider> preloadedImages = [];

  // Public static setter for hasAnimated
  static void setHasAnimated(bool value) => hasAnimated = value;
}

class _AnimatedChestState extends State<AnimatedChest>
    with SingleTickerProviderStateMixin {
  static const int totalFrames = 20;
  Timer? _timer;
  Future<void>? _preloadFuture;

  // Added state variable to track the current frame
  int _currentFrame = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    if (!AnimatedChest.hasPreloaded) {
      _preloadFuture = _preloadImages();
    } else if (widget.open && !AnimatedChest.hasAnimated) {
      // Only start animation if it hasn't played before
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
    }
  }

  String _getFramePath(int index) {
    return '${widget.basePath}/tile${index.toString().padLeft(3, '0')}.png';
  }

  Future<bool> _tryPreloadImage(String path) async {
    try {
      final image = AssetImage(path);
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
          print('Timeout loading image: $path');
          completer.complete(false);
        }
      });

      final success = await completer.future;

      // Remove listener to prevent memory leaks
      stream.removeListener(listener);

      if (success) {
        await precacheImage(image, context);
        AnimatedChest.preloadedImages.add(image);
        return true;
      }
      return false;
    } catch (e) {
      print('Exception loading image: $path');
      print(e);
      return false;
    }
  }

  Future<void> _preloadImages() async {
    if (AnimatedChest.hasPreloaded) {
      print('Images already preloaded, skipping...');
      return;
    }

    print('Starting initial image preload...');
    List<String> failedImages = [];

    for (int i = 0; i < totalFrames; i++) {
      final path = _getFramePath(i);
      final success = await _tryPreloadImage(path);

      if (!success) {
        failedImages.add(path);
      }
    }

    if (mounted) {
      setState(() {
        if (failedImages.isEmpty) {
          AnimatedChest.hasPreloaded = true;
          if (widget.open && !AnimatedChest.hasAnimated) {
            _startAnimation();
          }
        } else {
          widget.onPreloadError?.call();
        }
      });
    }
  }

  void _startAnimation() {
    if (AnimatedChest.hasAnimated ||
        !AnimatedChest.hasPreloaded ||
        AnimatedChest.preloadedImages.length < totalFrames) {
      print(
          'Animation blocked: animated=${AnimatedChest.hasAnimated}, preloaded=${AnimatedChest.hasPreloaded}, images=${AnimatedChest.preloadedImages.length}');
      return;
    }

    print('Starting chest animation');
    AnimatedChest.hasAnimated = true; // Mark as animated globally
    setState(() {
      _isAnimating = true;
      _currentFrame = 0;
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
  void didUpdateWidget(AnimatedChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.open && widget.open && !AnimatedChest.hasAnimated && AnimatedChest.hasPreloaded) {
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
    if (!AnimatedChest.hasPreloaded) {
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
      frameIndex = _currentFrame.clamp(0, totalFrames - 1);
    } else if (AnimatedChest.hasAnimated) {
      frameIndex = totalFrames - 1;
    } else {
      frameIndex = 0;
    }

    return SizedBox(
      width: 200,
      height: 200,
      child: Image(
        image: AnimatedChest.preloadedImages.isNotEmpty
            ? AnimatedChest.preloadedImages[frameIndex]
            : AssetImage('${widget.basePath}/tile000.png'),
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          print('Error rendering frame $frameIndex: $error');
          return Icon(Icons.broken_image, size: 48, color: Colors.red[300]);
        },
      ),
    );
  }
}
