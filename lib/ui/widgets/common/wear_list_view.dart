import 'package:flutter/material.dart';
import '../../../core/utils/watch_shape.dart';
import 'edge_scroll_indicator.dart';
import 'rotary_scroll_wrapper.dart';

/// A convenience widget that combines RotaryPageView with EdgeScrollIndicator
/// for a complete Wear OS scrolling experience.
class WearListView extends StatefulWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final void Function(int)? onPageChanged;
  final bool showScrollIndicator;
  final bool hapticEnabled;

  const WearListView({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.onPageChanged,
    this.showScrollIndicator = true,
    this.hapticEnabled = true,
  });

  @override
  State<WearListView> createState() => _WearListViewState();
}

class _WearListViewState extends State<WearListView> {
  final PageController _controller = PageController();
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients || widget.children.length <= 1) return;
    final page = _controller.page ?? 0;
    setState(() {
      _scrollProgress = page / (widget.children.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRound = WatchShape.isRound(context);
    return Stack(
      children: [
        RotaryPageView(
          controller: _controller,
          scrollDirection: widget.scrollDirection,
          onPageChanged: widget.onPageChanged,
          hapticEnabled: widget.hapticEnabled,
          children: widget.children,
        ),
        if (widget.showScrollIndicator && widget.children.length > 1)
          Positioned.fill(
            child: EdgeScrollIndicator(
              progress: _scrollProgress,
              isRound: isRound,
            ),
          ),
      ],
    );
  }
}

/// A simpler scrollable list that uses a standard ScrollController
/// instead of PageController, for non-paged content.
class WearScrollView extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final bool showScrollIndicator;
  final EdgeInsets? padding;

  const WearScrollView({
    super.key,
    required this.child,
    this.controller,
    this.showScrollIndicator = true,
    this.padding,
  });

  @override
  State<WearScrollView> createState() => _WearScrollViewState();
}

class _WearScrollViewState extends State<WearScrollView> {
  late ScrollController _controller;
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.maxScrollExtent <= 0) return;

    setState(() {
      _scrollProgress = position.pixels / position.maxScrollExtent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRound = WatchShape.isRound(context);
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _controller,
          padding: widget.padding,
          child: widget.child,
        ),
        if (widget.showScrollIndicator)
          Positioned.fill(
            child: EdgeScrollIndicator(
              progress: _scrollProgress,
              isRound: isRound,
            ),
          ),
      ],
    );
  }
}
