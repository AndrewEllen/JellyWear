import 'package:flutter/material.dart';

/// Visual scroll indicator that adapts to round or square watch displays.
/// Shows a track with a moving thumb to indicate scroll position.
class EdgeScrollIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final bool isRound;

  const EdgeScrollIndicator({
    required this.progress,
    required this.isRound,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _EdgeScrollPainter(progress: progress, isRound: isRound),
        size: Size.infinite,
      ),
    );
  }
}

class _EdgeScrollPainter extends CustomPainter {
  final double progress;
  final bool isRound;

  _EdgeScrollPainter({required this.progress, required this.isRound});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thumbPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isRound) {
      final margin = 6.0;
      final radius = (size.width / 2) - margin;
      final center = Offset(size.width / 2, size.height / 2);

      // Arc track: static
      final startAngle = -3.14 / 2 + 3.14 * 0.3; // top margin
      final sweepAngle = 3.14 * 0.4; // total arc span
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        trackPaint,
      );

      // Arc thumb: small portion moving
      final thumbSweep = sweepAngle * 0.2; // 20% of track
      final thumbStart = startAngle + (sweepAngle - thumbSweep) * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        thumbStart,
        thumbSweep,
        false,
        thumbPaint,
      );
    } else {
      // Rectangular track: static line
      final margin = 6.0;
      final trackLength = size.height * 0.6; // 60% of height
      final offsetX = size.width - margin;
      final startY = margin;
      canvas.drawLine(
        Offset(offsetX, startY),
        Offset(offsetX, startY + trackLength),
        trackPaint,
      );

      // Thumb: small moving handle
      final thumbLength = trackLength * 0.2; // 20% of track
      final thumbStart = startY + (trackLength - thumbLength) * progress;
      canvas.drawLine(
        Offset(offsetX, thumbStart),
        Offset(offsetX, thumbStart + thumbLength),
        thumbPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeScrollPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
