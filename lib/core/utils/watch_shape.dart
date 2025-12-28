import 'package:flutter/material.dart';

/// Utility for detecting and adapting to round vs square watch displays.
class WatchShape {
  /// Determines if the watch has a round display based on screen dimensions.
  /// Uses a simple heuristic: if width and height are nearly equal and the
  /// display isn't significantly rectangular, assume it's round.
  static bool isRound(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final aspectRatio = size.width / size.height;
    // Most round watches have aspect ratio very close to 1.0
    // Square watches also have 1.0, but we default to round for equal dimensions
    // since most Wear OS watches are round
    return aspectRatio > 0.95 && aspectRatio < 1.05;
  }

  /// Returns appropriate edge padding for round displays to prevent content
  /// from being clipped at the curved edges.
  static EdgeInsets edgePadding(BuildContext context) {
    if (isRound(context)) {
      final size = MediaQuery.of(context).size;
      // For round displays, content at edges needs extra padding
      // Use about 10% of the radius for comfortable viewing
      final padding = size.width * 0.07;
      return EdgeInsets.all(padding);
    }
    return const EdgeInsets.all(8);
  }

  /// Returns horizontal padding appropriate for the watch shape.
  static double horizontalPadding(BuildContext context) {
    if (isRound(context)) {
      return MediaQuery.of(context).size.width * 0.1;
    }
    return 12;
  }

  /// Returns the safe area for content, accounting for watch shape.
  static EdgeInsets safeContentPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final basePadding = mediaQuery.padding;
    final shapePadding = edgePadding(context);

    return EdgeInsets.only(
      left: basePadding.left + shapePadding.left,
      top: basePadding.top + shapePadding.top,
      right: basePadding.right + shapePadding.right,
      bottom: basePadding.bottom + shapePadding.bottom,
    );
  }

  /// Returns the usable screen diameter for round watches.
  static double usableWidth(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (isRound(context)) {
      // For round displays, usable width is less due to curved edges
      return size.width * 0.85;
    }
    return size.width - 24; // Account for basic padding on square
  }

  /// Returns the center point of the screen.
  static Offset screenCenter(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Offset(size.width / 2, size.height / 2);
  }
}
