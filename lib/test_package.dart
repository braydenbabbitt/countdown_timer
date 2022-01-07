import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedCircleProgressBar extends StatefulWidget {
  // Required properties
  final double value;
  final Color fillColor;

  // Optional properties -- Defaults
  final double strokeSizePercentage; // 0.075
  final Color backgroundColor; // Colors.transparent
  final Curve animationCurve; // Curves.easeInOut
  final Duration animationDuration; // Duration(milliseconds: 500)
  final double animationStartAngle; // 90
  final bool counterClockwise; // false

  // Nullable properties -- Behavior if null
  final double? height; // Will assume height of container
  final double? width; // Will assume width of container
  final Widget? child; // Will skip painting any child
  final double? initialValue; // Will not animate the first value

  const AnimatedCircleProgressBar({
    Key? key,
    required this.value,
    required this.fillColor,
    this.strokeSizePercentage = 0.075,
    this.backgroundColor = Colors.transparent,
    this.animationCurve = Curves.easeInOut,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationStartAngle = (-90 * (pi / 180)),
    this.counterClockwise = false,
    this.height,
    this.width,
    this.child,
    this.initialValue,
  }) : super(key: key);

  @override
  State<AnimatedCircleProgressBar> createState() => _AnimatedCircleProgressBarState();
}

class _AnimatedCircleProgressBarState extends State<AnimatedCircleProgressBar> with
    SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late Tween<double> _valueTween;

  @override
  void initState() {
    super.initState();

    _valueTween = Tween<double>(
      begin: widget.initialValue ?? widget.value,
      end: widget.value,
    );

    _controller = AnimationController(
      value: widget.value,
      duration: widget.animationDuration,
      vsync: this,
    );
    _controller.forward();

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _curvedAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: widget.height,
        width: widget.width,
        child: AnimatedBuilder(
          animation: _curvedAnimation,
          child: (widget.child != null) ? Center(
            heightFactor: widget.height,
            widthFactor: widget.width,
            child: widget.child,
          ) : null,
          builder: (context, child) {
            return CustomPaint(
              child: child,
              painter: _AnimatedCircleProgressBarPainter(
                percentage: _valueTween.evaluate(_curvedAnimation),
                strokeSizePercentage: widget.strokeSizePercentage,
                animationStartAngle: widget.animationStartAngle,
                color: widget.fillColor,
                counterClockwise: widget.counterClockwise,
                backgroundColor: widget.backgroundColor,
                height: widget.height,
                width: widget.width,
              ),
            );
          },
        )
    );
  }

  @override
  void didUpdateWidget(AnimatedCircleProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.duration = Duration(milliseconds: (500).toInt());

    if (widget.value != oldWidget.value) {
      _valueTween = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      );

      _controller
        ..value = 0
        ..forward();
    }
  }
}

class _AnimatedCircleProgressBarPainter extends CustomPainter {
  // Required properties
  final Color color;
  final double percentage;
  final double strokeSizePercentage;
  final double animationStartAngle;
  final bool counterClockwise;

  // Optional properties -- Default value
  final Color backgroundColor; // Colors.transparent

  // Nullable properties -- Behavior if null
  final double? height; // Will default to paint size.height property
  final double? width; // Will default to paint size.width property

  _AnimatedCircleProgressBarPainter({
    required this.color,
    required this.percentage,
    required this.strokeSizePercentage,
    required this.animationStartAngle,
    required this.counterClockwise,
    this.backgroundColor = Colors.transparent,
    this.height,
    this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = backgroundColor
      ..strokeWidth = size.width * strokeSizePercentage;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = size.width * strokeSizePercentage
      ..strokeCap = StrokeCap.round;

    final direction = (counterClockwise) ? 1 : -1;
    final circleOffset = Offset(size.width / 2, size.width / 2);
    final circleRect = Rect.fromCenter(center: circleOffset, width: size.width, height: size.height);
    final arcAngle = direction * (2 * pi * percentage);

    canvas.drawArc(circleRect, 0, 360, false, backgroundPaint);
    if (percentage >= 0.01) canvas.drawArc(circleRect, animationStartAngle, arcAngle, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final old = (oldDelegate as _AnimatedCircleProgressBarPainter);
    return old.percentage != percentage;
  }
}