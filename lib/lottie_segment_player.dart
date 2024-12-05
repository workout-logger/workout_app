import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieSegmentPlayer extends StatefulWidget {
  final String animationPath;
  final double endFraction;
  final double? width; // Optional width
  final double? height; // Optional height
  final bool progressiveLoad; // Progressive loading toggle
  final int steps; // Number of progressive steps
  final RenderCache renderCache; // Render cache mode

  const LottieSegmentPlayer({
    Key? key,
    required this.animationPath,
    required this.endFraction,
    this.width,
    this.height,
    this.progressiveLoad = false, // Default is not progressive
    this.steps = 5, // Default number of steps
    this.renderCache = RenderCache.raster, // Default caching mode
  }) : super(key: key);

  @override
  _LottieSegmentPlayerState createState() => _LottieSegmentPlayerState();
}

class _LottieSegmentPlayerState extends State<LottieSegmentPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentFraction = 0; // Track the current progress

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    if (widget.progressiveLoad) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _loadNextSegment();
        }
      });
    }
  }

  void _loadNextSegment() {
    if (_currentFraction < widget.endFraction) {
      double stepSize = widget.endFraction / widget.steps;
      _currentFraction += stepSize;
      if (_currentFraction > widget.endFraction) {
        _currentFraction = widget.endFraction; // Cap the fraction
      }

      _controller.value = 0;
      _controller.animateTo(
        _currentFraction,
        duration: Duration(
          milliseconds: (_currentFraction * _controller.duration!.inMilliseconds).round(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget.animationPath,
      controller: _controller,
      width: widget.width, // Set the width
      height: widget.height, // Set the height
      fit: BoxFit.contain, // Ensure the animation scales properly
      renderCache: widget.renderCache, // Apply caching mode
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        if (widget.progressiveLoad) {
          _loadNextSegment(); // Start progressive loading
        } else {
          _controller.animateTo(
            widget.endFraction,
            duration: Duration(
              milliseconds: (widget.endFraction *
                      _controller.duration!.inMilliseconds)
                  .round(),
            ),
          );
        }
      },
    );
  }
}
