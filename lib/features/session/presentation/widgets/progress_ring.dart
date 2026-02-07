import 'dart:math';
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final Duration elapsed;
  final Duration cycleDuration; // 60 minutes
  final List<Color> cycleColors; // subtle tones (2-3)
  final Color inactiveColor;

  const ProgressRing({
    super.key,
    required this.elapsed,
    required this.cycleDuration,
    required this.cycleColors,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final cycleSeconds = cycleDuration.inSeconds == 0 ? 1 : cycleDuration.inSeconds;
    final elapsedSeconds = elapsed.inSeconds;

    // How many full 60-min cycles completed
    final cycleIndex = elapsedSeconds ~/ cycleSeconds;

    // Progress within the current cycle (0..1)
    final withinCycleSeconds = elapsedSeconds % cycleSeconds;
    final progress = (withinCycleSeconds / cycleSeconds).clamp(0.0, 1.0);

    // Pick the tone for this cycle (subtle shift)
    final activeColor = cycleColors[cycleIndex % cycleColors.length];

    return CustomPaint(
      painter: _ProgressRingPainter(
        progress: progress,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _ProgressRingPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    const totalTicks = 60;       // ✅ your choice
    const tickLength = 10.0;
    const tickWidth = 2.0;

    final activeTicks = (totalTicks * progress).floor();

    for (int i = 0; i < totalTicks; i++) {
      final angle = (2 * pi / totalTicks) * i - pi / 2;
      final isActive = i < activeTicks;

      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..strokeWidth = tickWidth
        ..strokeCap = StrokeCap.round;

      final outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final innerPoint = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
