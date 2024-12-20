import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieSegmentPlayer extends StatefulWidget {
  final String animationPath;
  final double endFraction;
  final double? width; // Optional width
  final double? height; // Optional height
  final bool progressiveLoad; // Progressive loading toggle
  final int steps; // Number of progressive steps
  final FilterQuality filterQuality; // Filter quality for rendering

  const LottieSegmentPlayer({
    super.key,
    required this.animationPath,
    required this.endFraction,
    this.width,
    this.height,
    this.progressiveLoad = false, // Default is not progressive
    this.steps = 5, // Default number of steps
    this.filterQuality = FilterQuality.low, // Default filter quality
  });

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

    // Initialize the controller with the specified endFraction as upperBound
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: widget.endFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (widget.progressiveLoad) {
      _loadNextSegment();
    } else {
      _controller.repeat();
    }
  }

  void _loadNextSegment() {
    if (_currentFraction < widget.endFraction) {
      double stepSize = widget.endFraction / widget.steps;
      _currentFraction += stepSize;
      if (_currentFraction > widget.endFraction) {
        _currentFraction = widget.endFraction; // Cap the fraction
      }

      _controller.animateTo(
        _currentFraction,
        duration: Duration(
          milliseconds: ((_currentFraction - _controller.value) *
                  _controller.duration!.inMilliseconds)
              .round(),
        ),
      ).whenComplete(() {
        // Delay before loading the next segment
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadNextSegment();
        });
      });
    } else {
      // Restart the progressive loading
      _currentFraction = 0;
      _controller.value = 0;
      _loadNextSegment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget.animationPath,
      controller: _controller,
      width: widget.width, // Set the width
      height: widget.height, // Set the height
      fit: BoxFit.contain, // Ensure the animation scales properly
      filterQuality: widget.filterQuality, // Apply filter quality
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        _startAnimation();
      },
    );
  }
}
