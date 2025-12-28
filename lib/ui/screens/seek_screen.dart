import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wearable_rotary/wearable_rotary.dart';
import '../../core/theme/wear_theme.dart';

/// Seek screen with arc progress ring UI and rotary control.
class SeekScreen extends StatefulWidget {
  const SeekScreen({super.key});

  @override
  State<SeekScreen> createState() => _SeekScreenState();
}

class _SeekScreenState extends State<SeekScreen> {
  StreamSubscription<RotaryEvent>? _rotarySubscription;

  // Playback state (TODO: get from remote state)
  int _positionTicks = 0;
  int _durationTicks = 600000000; // 1 minute default
  bool _isDragging = false;

  // Seek increment in ticks (10 seconds)
  static const int _seekIncrement = 100000000;

  @override
  void initState() {
    super.initState();
    _rotarySubscription = rotaryEvents.listen(_onRotaryEvent);
  }

  @override
  void dispose() {
    _rotarySubscription?.cancel();
    super.dispose();
  }

  void _onRotaryEvent(RotaryEvent event) {
    HapticFeedback.lightImpact();

    setState(() {
      _isDragging = true;
      if (event.direction == RotaryDirection.clockwise) {
        _positionTicks = math.min(_positionTicks + _seekIncrement, _durationTicks);
      } else {
        _positionTicks = math.max(_positionTicks - _seekIncrement, 0);
      }
    });

    // Debounce seek command
    _scheduleSeek();
  }

  Timer? _seekDebounce;

  void _scheduleSeek() {
    _seekDebounce?.cancel();
    _seekDebounce = Timer(const Duration(milliseconds: 500), () {
      _sendSeek();
      setState(() => _isDragging = false);
    });
  }

  Future<void> _sendSeek() async {
    // TODO: Send seek command to Jellyfin
    HapticFeedback.mediumImpact();
  }

  String _formatTime(int ticks) {
    final seconds = ticks ~/ 10000000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;

    if (hours > 0) {
      return '${hours}:${(minutes % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return '${minutes}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_durationTicks <= 0) return 0;
    return _positionTicks / _durationTicks;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Stack(
        children: [
          // Arc progress ring
          CustomPaint(
            size: size,
            painter: _ArcProgressPainter(
              progress: _progress,
              isDragging: _isDragging,
            ),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_positionTicks),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isDragging ? WearTheme.jellyfinPurple : null,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(_durationTicks),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Rotate to seek',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WearTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          // Back button
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: WearTheme.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcProgressPainter extends CustomPainter {
  final double progress;
  final bool isDragging;

  _ArcProgressPainter({
    required this.progress,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    // Track
    final trackPaint = Paint()
      ..color = WearTheme.surfaceVariant
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Full circle track
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = isDragging ? WearTheme.jellyfinPurple : WearTheme.jellyfinPurpleDark
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw progress arc from top (- pi/2)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Draw position indicator dot
    if (progress > 0) {
      final indicatorAngle = startAngle + sweepAngle;
      final indicatorX = center.dx + radius * math.cos(indicatorAngle);
      final indicatorY = center.dy + radius * math.sin(indicatorAngle);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(indicatorX, indicatorY), 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDragging != isDragging;
  }
}
