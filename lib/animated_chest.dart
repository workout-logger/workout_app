import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedChest extends StatefulWidget {
  final bool open;
  final VoidCallback? onAnimationComplete;

  const AnimatedChest({
    Key? key,
    required this.open,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  _AnimatedChestState createState() => _AnimatedChestState();
}

class _AnimatedChestState extends State<AnimatedChest> {
  static const int totalFrames = 20; // 0 to 19
  int currentFrame = 0;
  Timer? _timer;
  bool _imagesPreloaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    // Preload all frames
    for (int i = 0; i < totalFrames; i++) {
      final frameName = 'assets/images/chests/tile${i.toString().padLeft(3, '0')}.png';
      await precacheImage(AssetImage(frameName), context);
    }

    // Once all images are preloaded, update state
    setState(() {
      _imagesPreloaded = true;
    });

    // If widget.open is already true, start animation now
    if (widget.open) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.open && widget.open && _imagesPreloaded) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    currentFrame = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        currentFrame++;
        if (currentFrame >= totalFrames) {
          currentFrame = totalFrames - 1;
          _timer?.cancel();
          widget.onAnimationComplete?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_imagesPreloaded) {
      // Show a placeholder while images load
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final frameIndex = currentFrame.clamp(0, totalFrames - 1);
    final frameName = 'assets/images/chests/tile${frameIndex.toString().padLeft(3, '0')}.png';

    return SizedBox(
      width: 200,
      height: 200,
      child: Image.asset(
        frameName,
        fit: BoxFit.fill,
      ),
    );
  }
}
