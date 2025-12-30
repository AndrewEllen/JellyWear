import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

/// Wear-style scaling wheel list with rotary scrolling.
///
/// - Uses ListWheelScrollView (fixed item extent).
/// - Rotary events scroll by pixels using jumpTo() with ClampingScrollPhysics.
/// - After rotary stops (debounce), restores FixedExtentScrollPhysics and snaps to nearest item.
/// - No ScrollEndNotification snapping (prevents animateToItem -> scroll end -> animate loop).
class RotaryWheelList<T> extends StatefulWidget {
  final List<T> items;
  final double itemExtent;

  final Widget Function(BuildContext context, T item, int index, bool isCentered) itemBuilder;
  final void Function(T item, int index)? onItemTap;
  final void Function(T item, int index)? onCenteredItemChanged;

  final FixedExtentScrollController? controller;

  // Rotary tuning
  final double rotaryScrollDeltaPx;
  final double hapticTickEveryPx;
  final Duration rotaryDebounceDuration;

  // Scale/opacity tuning
  final double minScale;
  final double minOpacity;
  final double scaleDropPerItem;
  final double opacityDropPerItem;

  // Wheel tuning
  final double diameterRatio;
  final double perspective;

  // Optional (UI choice)
  final bool showScrollIndicator;

  const RotaryWheelList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onItemTap,
    this.onCenteredItemChanged,
    this.controller,
    this.itemExtent = 84.0,
    this.rotaryScrollDeltaPx = 8.0,
    this.hapticTickEveryPx = 60.0,
    this.rotaryDebounceDuration = const Duration(milliseconds: 250),
    this.minScale = 0.75,
    this.minOpacity = 0.5,
    this.scaleDropPerItem = 0.25,
    this.opacityDropPerItem = 0.5,
    this.diameterRatio = 3.0,
    this.perspective = 0.002,
    this.showScrollIndicator = false,
  });

  @override
  State<RotaryWheelList<T>> createState() => _RotaryWheelListState<T>();
}

class _RotaryWheelListState<T> extends State<RotaryWheelList<T>> {
  late final FixedExtentScrollController _controller =
      widget.controller ?? FixedExtentScrollController();

  late final StreamSubscription<RotaryEvent> _rotarySubscription;

  Timer? _rotaryDebounce;

  // When false, we use ClampingScrollPhysics for smooth pixel rotary scrolling.
  bool _snapEnabled = true;

  // Prevent repeated boundary haptics.
  bool _boundaryLock = false;

  // Medium tick accumulation.
  double _pixelAccum = 0;

  // Prevent re-entrant snap calls.
  bool _snapping = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    _rotarySubscription = rotaryEvents.listen((RotaryEvent event) {
      if (!_controller.hasClients) return;
      if (widget.items.isEmpty) return;

      final position = _controller.position;
      if (position.maxScrollExtent <= 0) return;

      // During rotary, disable snapping physics to avoid jitter.
      if (_snapEnabled) {
        setState(() => _snapEnabled = false);
      }

      _rotaryDebounce?.cancel();

      final int direction = event.direction == RotaryDirection.clockwise ? 1 : -1;

      final double target = (position.pixels + direction * widget.rotaryScrollDeltaPx)
          .clamp(position.minScrollExtent, position.maxScrollExtent);

      position.jumpTo(target);

      // Haptic tick
      _pixelAccum += widget.rotaryScrollDeltaPx.abs();
      if (_pixelAccum >= widget.hapticTickEveryPx) {
        HapticFeedback.mediumImpact();
        _pixelAccum = 0;
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

      // Debounce: restore snapping + snap to nearest item.
      _rotaryDebounce = Timer(widget.rotaryDebounceDuration, () {
        if (!mounted) return;
        if (!_snapEnabled) setState(() => _snapEnabled = true);
        _snapToNearestItem();
      });
    });
  }

  void _snapToNearestItem() {
    if (_snapping) return;
    if (!_controller.hasClients) return;
    if (widget.items.isEmpty) return;

    final double offset = _controller.offset;
    final int nearestIndex =
    (offset / widget.itemExtent).round().clamp(0, widget.items.length - 1);

    // If we’re already basically there, do nothing.
    final int currentSelected = _safeSelectedItem();
    if (currentSelected == nearestIndex) return;

    _snapping = true;

    _controller
        .animateToItem(
      nearestIndex,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    )
        .whenComplete(() {
      _snapping = false;
    });
  }

  int _safeSelectedItem() {
    try {
      return _controller.selectedItem;
    } catch (_) {
      // selectedItem can throw if not attached yet.
      final idx = (_controller.hasClients ? (_controller.offset / widget.itemExtent).round() : 0);
      return idx.clamp(0, widget.items.length - 1);
    }
  }

  double _centerIndex() {
    if (!_controller.hasClients) return 0.0;
    return _controller.offset / widget.itemExtent;
  }

  @override
  void dispose() {
    _rotaryDebounce?.cancel();
    _rotarySubscription.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centerIndex = _centerIndex();

    final ScrollPhysics physics =
    _snapEnabled ? const FixedExtentScrollPhysics() : const ClampingScrollPhysics();

    final wheel = ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: widget.itemExtent,
      diameterRatio: widget.diameterRatio,
      perspective: widget.perspective,
      useMagnifier: false,
      physics: physics,
      onSelectedItemChanged: (index) {
        if (index < 0 || index >= widget.items.length) return;
        widget.onCenteredItemChanged?.call(widget.items[index], index);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.items.length,
        builder: (context, index) {
          if (index < 0 || index >= widget.items.length) return null;

          final distance = (index - centerIndex).abs();

          final scale =
          (1.0 - (distance * widget.scaleDropPerItem)).clamp(widget.minScale, 1.0);
          final opacity =
          (1.0 - (distance * widget.opacityDropPerItem)).clamp(widget.minOpacity, 1.0);

          final isCentered = distance < 0.5;

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onItemTap == null
                    ? null
                    : () {
                  HapticFeedback.lightImpact();
                  widget.onItemTap!(widget.items[index], index);
                },
                child: widget.itemBuilder(context, widget.items[index], index, isCentered),
              ),
            ),
          );
        },
      ),
    );

    if (!widget.showScrollIndicator) return wheel;

    return Stack(
      children: [
        wheel,
        Positioned(
          right: 6,
          top: 18,
          bottom: 18,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
