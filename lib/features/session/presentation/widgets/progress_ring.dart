import 'dart:math';
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // Value between 0.0 and 1.0
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProgressRingPainter(
        progress: progress,
        color: color,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - (strokeWidth / 2);
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}