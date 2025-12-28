import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

/// Mixin that provides rotary scroll functionality with haptic feedback and page snapping.
/// Based on user-provided implementation optimized for Wear OS.
mixin RotaryScrollMixin<T extends StatefulWidget> on State<T> {
  late PageController _pageController;
  StreamSubscription<RotaryEvent>? _rotarySubscription;

  Timer? _rotaryDebounce;
  bool _snapEnabled = true;
  bool _boundaryLock = false;
  double _pixelAccum = 0;

  int get numberOfPages;
  PageController get pageController => _pageController;
  bool get snapEnabled => _snapEnabled;

  /// Override to customize scroll sensitivity (pixels per rotary detent).
  double get scrollDelta => 6;

  /// Override to customize haptic feedback interval (pixels between ticks).
  double get hapticInterval => 60;

  /// Override to enable/disable haptic feedback.
  bool get hapticEnabled => true;

  void initRotaryScroll(PageController controller) {
    _pageController = controller;
    _rotarySubscription = rotaryEvents.listen(_onRotaryEvent);
    _pageController.addListener(_onPageControllerUpdate);
  }

  void disposeRotaryScroll() {
    _rotarySubscription?.cancel();
    _rotaryDebounce?.cancel();
    _pageController.removeListener(_onPageControllerUpdate);
  }

  void _onPageControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onRotaryEvent(RotaryEvent event) {
    if (!_pageController.hasClients) return;

    // Disable snapping during rotary interaction
    if (_snapEnabled) {
      setState(() => _snapEnabled = false);
    }

    // Cancel pending snap recovery
    _rotaryDebounce?.cancel();

    final position = _pageController.position;

    final int direction =
        event.direction == RotaryDirection.clockwise ? 1 : -1;

    final double target = (position.pixels + direction * scrollDelta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    // Pixel scroll
    position.jumpTo(target);

    // Tick haptic per interval
    if (hapticEnabled) {
      _pixelAccum += scrollDelta.abs();
      if (_pixelAccum >= hapticInterval) {
        HapticFeedback.mediumImpact();
        _pixelAccum = 0;
      }
    }

    // Boundary bump
    final bool atTop = target <= position.minScrollExtent + 1;
    final bool atBottom = target >= position.maxScrollExtent - 1;

    if ((atTop || atBottom) && !_boundaryLock) {
      _boundaryLock = true;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 250), () {
        _boundaryLock = false;
      });
    }

    // When rotary stops, restore snapping + snap to nearest page
    _rotaryDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!_snapEnabled && mounted) {
        setState(() => _snapEnabled = true);
      }
      _snapToNearestPage();
    });
  }

  void _snapToNearestPage() {
    if (!_pageController.hasClients) return;

    final double page = _pageController.page ?? 0.0;
    final int nearest = page.round();

    _pageController.animateToPage(
      nearest,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  /// Returns scroll progress normalized from 0.0 to 1.0.
  double get scrollProgress {
    if (!_pageController.hasClients) return 0;
    final page = _pageController.page ?? 0.0;
    if (numberOfPages <= 1) return 0;
    return page / (numberOfPages - 1);
  }

  /// Returns the current page index.
  int get currentPage {
    if (!_pageController.hasClients) return 0;
    return (_pageController.page ?? 0).round();
  }
}

/// A stateful wrapper that combines rotary scroll with a PageView.
class RotaryPageView extends StatefulWidget {
  final List<Widget> children;
  final PageController? controller;
  final Axis scrollDirection;
  final void Function(int)? onPageChanged;
  final bool hapticEnabled;

  const RotaryPageView({
    super.key,
    required this.children,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.onPageChanged,
    this.hapticEnabled = true,
  });

  @override
  State<RotaryPageView> createState() => _RotaryPageViewState();
}

class _RotaryPageViewState extends State<RotaryPageView>
    with RotaryScrollMixin {
  late PageController _controller;

  @override
  int get numberOfPages => widget.children.length;

  @override
  bool get hapticEnabled => widget.hapticEnabled;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PageController();
    initRotaryScroll(_controller);
  }

  @override
  void dispose() {
    disposeRotaryScroll();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      scrollDirection: widget.scrollDirection,
      pageSnapping: snapEnabled,
      onPageChanged: widget.onPageChanged,
      children: widget.children,
    );
  }
}
