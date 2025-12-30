import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/jellyfin_constants.dart';
import '../../core/theme/wear_theme.dart';
import '../../data/jellyfin/jellyfin_client_wrapper.dart';
import '../../data/models/library_item.dart';
import '../../data/repositories/library_repository.dart';
import '../../state/session_state.dart';
import '../widgets/common/rotary_wheel_list.dart';

class MediaSelectionScreen extends StatefulWidget {
  const MediaSelectionScreen({super.key});

  @override
  State<MediaSelectionScreen> createState() => _MediaSelectionScreenState();
}

class _MediaSelectionScreenState extends State<MediaSelectionScreen> {
  bool _loading = true;
  String? _error;

  // Limits tuned for Wear.
  static const int _continueLimit = 14;
  static const int _nextUpLimit = 14;

  List<LibraryView> _views = [];
  List<LibraryItem> _continue = [];
  List<LibraryItem> _nextUp = [];

  late final _JellyfinHttp _http;

  @override
  void initState() {
    super.initState();
    _http = _JellyfinHttp(context.read<JellyfinClientWrapper>());
    _load();
  }

  Future<void> _load() async {
    try {
      final libraryRepo = context.read<LibraryRepository>();

      final results = await Future.wait([
        _http.getUserViews(),
        libraryRepo.getContinueWatching(limit: _continueLimit),
        _http.getNextUp(limit: _nextUpLimit),
      ]);

      if (!mounted) return;

      setState(() {
        _views = results[0] as List<LibraryView>;
        _continue = results[1] as List<LibraryItem>;
        _nextUp = results[2] as List<LibraryItem>;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('MediaSelectionScreen _load error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openDetails(LibraryItem item) async {
    HapticFeedback.lightImpact();
    final bgUrl = context.read<LibraryRepository>().getImageUrl(item.id, maxWidth: 520);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MediaDetailsScreen(
          item: item,
          backgroundUrl: bgUrl,
          onPlay: () async {
            HapticFeedback.mediumImpact();
            await context.read<SessionState>().playOnTarget([item.id]);
            if (Navigator.canPop(context)) Navigator.pop(context);
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _openContinue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SectionScreen(
          title: 'Continue Watching',
          items: _continue,
          onTap: _openDetails,
          emptyText: 'Nothing to continue',
        ),
      ),
    );
  }

  Future<void> _openNextUp() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SectionScreen(
          title: 'Next Up',
          items: _nextUp,
          onTap: _openDetails,
          emptyText: 'No Next Up items',
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController();

    final query = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Search'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            decoration: const InputDecoration(hintText: 'Title / artist / show'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Go')),
          ],
        );
      },
    );

    if (!mounted) return;
    if (query == null || query.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SearchResultsScreen(
          query: query,
          http: _http,
          onTap: _openDetails,
        ),
      ),
    );
  }

  Future<void> _openView(LibraryView view) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LibraryBrowseScreen(
          http: _http,
          title: view.name,
          parentId: view.id,
          onTap: _openDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: WearTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WearTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipOval(
            child: _HomePage(
              views: _views,
              continueItems: _continue,
              nextUpItems: _nextUp,
              onSearch: _openSearch,
              onOpenView: _openView,
              onOpenContinue: _openContinue,
              onOpenNextUp: _openNextUp,
            ),
          ),
        ),
      ),
    );
  }
}

enum _HomeKind { search, cont, nextUp, view }

class _HomeItem {
  final _HomeKind kind;
  final LibraryView? view;

  const _HomeItem._(this.kind, this.view);

  const _HomeItem.search() : this._(_HomeKind.search, null);
  const _HomeItem.continueWatching() : this._(_HomeKind.cont, null);
  const _HomeItem.nextUp() : this._(_HomeKind.nextUp, null);
  const _HomeItem.view(LibraryView v) : this._(_HomeKind.view, v);
}

class _HomePage extends StatefulWidget {
  final List<LibraryView> views;
  final List<LibraryItem> continueItems;
  final List<LibraryItem> nextUpItems;

  final Future<void> Function() onSearch;
  final Future<void> Function(LibraryView view) onOpenView;
  final Future<void> Function() onOpenContinue;
  final Future<void> Function() onOpenNextUp;

  const _HomePage({
    required this.views,
    required this.continueItems,
    required this.nextUpItems,
    required this.onSearch,
    required this.onOpenView,
    required this.onOpenContinue,
    required this.onOpenNextUp,
  });

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _centerIndex = 0;
  static const int _bgCacheWidth = 520;

  String? _bgUrlForCenteredItem(_HomeItem item) {
    final repo = context.read<LibraryRepository>();

    String? firstContinue() {
      if (widget.continueItems.isEmpty) return null;
      return repo.getImageUrl(widget.continueItems.first.id, maxWidth: _bgCacheWidth);
    }

    String? firstNextUp() {
      if (widget.nextUpItems.isEmpty) return null;
      return repo.getImageUrl(widget.nextUpItems.first.id, maxWidth: _bgCacheWidth);
    }

    switch (item.kind) {
      case _HomeKind.search:
        return firstContinue() ?? firstNextUp();

      case _HomeKind.cont:
        return firstContinue() ?? firstNextUp();

      case _HomeKind.nextUp:
        return firstNextUp() ?? firstContinue();

      case _HomeKind.view:
        final viewId = item.view?.id;
        if (viewId == null) return firstContinue() ?? firstNextUp();

        final viewUrl = repo.getImageUrl(viewId, maxWidth: _bgCacheWidth);
        if (viewUrl != null && viewUrl.isNotEmpty) return viewUrl;

        return firstContinue() ?? firstNextUp();
    }
  }

  ImageProvider? _provider(String? url) {
    if (url == null || url.isEmpty) return null;
    return ResizeImage(CachedNetworkImageProvider(url), width: _bgCacheWidth);
  }

  @override
  Widget build(BuildContext context) {
    final items = <_HomeItem>[
      const _HomeItem.search(),
      const _HomeItem.continueWatching(),
      const _HomeItem.nextUp(),
      ...widget.views.map(_HomeItem.view),
    ];

    final centered = (_centerIndex >= 0 && _centerIndex < items.length) ? items[_centerIndex] : items.first;
    final bg = _provider(_bgUrlForCenteredItem(centered));

    return Stack(
      children: [
        Positioned.fill(child: _BackgroundImage(imageProvider: bg)),

        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: RotaryWheelList<_HomeItem>(
            items: items,
            itemExtent: 78,
            showScrollIndicator: false,
            onCenteredItemChanged: (_, idx) => setState(() => _centerIndex = idx),
            onItemTap: (item, index) async {
              HapticFeedback.lightImpact();

              switch (item.kind) {
                case _HomeKind.search:
                  await widget.onSearch();
                  break;
                case _HomeKind.cont:
                  await widget.onOpenContinue();
                  break;
                case _HomeKind.nextUp:
                  await widget.onOpenNextUp();
                  break;
                case _HomeKind.view:
                  if (item.view != null) await widget.onOpenView(item.view!);
                  break;
              }
            },
            itemBuilder: (context, item, index, isCentered) {
              late final String title;
              late final IconData icon;

              switch (item.kind) {
                case _HomeKind.search:
                  title = 'Search';
                  icon = Icons.search;
                  break;
                case _HomeKind.cont:
                  title = 'Continue';
                  icon = Icons.play_circle;
                  break;
                case _HomeKind.nextUp:
                  title = 'Next Up';
                  icon = Icons.skip_next;
                  break;
                case _HomeKind.view:
                  title = item.view?.name ?? 'Library';
                  icon = Icons.video_library;
                  break;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(isCentered ? 0.55 : 0.35),
                  borderRadius: BorderRadius.circular(28),
                  border: isCentered
                      ? Border.all(color: WearTheme.jellyfinPurple, width: 1.5)
                      : Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isCentered ? WearTheme.jellyfinPurple : Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: isCentered ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionScreen extends StatelessWidget {
  final String title;
  final List<LibraryItem> items;
  final Future<void> Function(LibraryItem item) onTap;
  final String? emptyText;

  const _SectionScreen({
    required this.title,
    required this.items,
    required this.onTap,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipOval(
            child: _WheelSectionPage(
              title: title,
              items: items,
              onTap: onTap,
              emptyText: emptyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelSectionPage extends StatefulWidget {
  final String title;
  final List<LibraryItem> items;
  final Future<void> Function(LibraryItem item) onTap;
  final String? emptyText;

  const _WheelSectionPage({
    required this.title,
    required this.items,
    required this.onTap,
    this.emptyText,
  });

  @override
  State<_WheelSectionPage> createState() => _WheelSectionPageState();
}

class _WheelSectionPageState extends State<_WheelSectionPage> {
  int _centerIndex = 0;
  static const int _bgCacheWidth = 520;

  String? _bgUrlForIndex(int index) {
    if (index < 0 || index >= widget.items.length) return null;
    final repo = context.read<LibraryRepository>();
    return repo.getImageUrl(widget.items[index].id, maxWidth: _bgCacheWidth);
  }

  ImageProvider? _provider(String? url) {
    if (url == null || url.isEmpty) return null;
    return ResizeImage(CachedNetworkImageProvider(url), width: _bgCacheWidth);
  }

  Future<void> _prefetchNeighbors() async {
    if (!mounted) return;
    if (widget.items.isEmpty) return;

    final urls = <String?>[
      _bgUrlForIndex(_centerIndex),
      _bgUrlForIndex(_centerIndex - 1),
      _bgUrlForIndex(_centerIndex + 1),
    ].whereType<String>().toSet();

    for (final url in urls) {
      try {
        final p = _provider(url);
        if (p != null) await precacheImage(p, context);
      } catch (_) {
        // ignore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _provider(_bgUrlForIndex(_centerIndex));

    return Stack(
      children: [
        Positioned.fill(child: _BackgroundImage(imageProvider: bg)),

        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: widget.items.isEmpty
              ? Center(
            child: Text(
              widget.emptyText ?? 'No items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WearTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          )
              : RotaryWheelList<LibraryItem>(
            items: widget.items,
            itemExtent: 78,
            showScrollIndicator: false,
            onCenteredItemChanged: (_, idx) {
              if (_centerIndex == idx) return;
              setState(() => _centerIndex = idx);
              unawaited(_prefetchNeighbors());
            },
            onItemTap: (item, _) => widget.onTap(item),
            itemBuilder: (context, item, index, isCentered) {
              return _TitleCard(title: item.name, subtitle: item.subtitle, isCentered: isCentered);
            },
          ),
        ),

        Positioned(
          top: 24,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.34),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  final ImageProvider? imageProvider;

  const _BackgroundImage({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: imageProvider == null
          ? Container(
        key: const ValueKey('no-bg'),
        color: WearTheme.background,
      )
          : Stack(
        key: ValueKey(imageProvider),
        fit: StackFit.expand,
        children: [
          Image(image: imageProvider!, fit: BoxFit.cover, filterQuality: FilterQuality.low),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const SizedBox.expand(),
          ),
          Container(color: Colors.black.withOpacity(0.55)),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.60),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isCentered;

  const _TitleCard({
    required this.title,
    required this.subtitle,
    required this.isCentered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(isCentered ? 0.55 : 0.35),
        borderRadius: BorderRadius.circular(26),
        border: isCentered ? Border.all(color: WearTheme.jellyfinPurple, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_fill,
            size: 22,
            color: isCentered ? WearTheme.jellyfinPurple : WearTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isCentered ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WearTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaDetailsScreen extends StatelessWidget {
  final LibraryItem item;
  final String? backgroundUrl;
  final Future<void> Function() onPlay;

  const _MediaDetailsScreen({
    required this.item,
    required this.backgroundUrl,
    required this.onPlay,
  });

  static const int _detailsBgCacheWidth = 520;

  ImageProvider? _provider() {
    if (backgroundUrl == null || backgroundUrl!.isEmpty) return null;
    return ResizeImage(CachedNetworkImageProvider(backgroundUrl!), width: _detailsBgCacheWidth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipOval(
            child: Stack(
              children: [
                Positioned.fill(child: _BackgroundImage(imageProvider: _provider())),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WearTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            item.overview ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: item.isPlayable ? () => onPlay() : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultsScreen extends StatefulWidget {
  final String query;
  final _JellyfinHttp http;
  final Future<void> Function(LibraryItem item) onTap;

  const _SearchResultsScreen({
    required this.query,
    required this.http,
    required this.onTap,
  });

  @override
  State<_SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<_SearchResultsScreen> {
  bool _loading = true;
  String? _error;
  List<LibraryItem> _items = [];
  int _center = 0;

  static const int _bgCacheWidth = 520;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final items = await widget.http.searchItems(query: widget.query, limit: 30);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
        _center = 0;
      });
    } catch (e, st) {
      debugPrint('SearchResults _run error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  ImageProvider? _bgProvider() {
    if (_items.isEmpty) return null;
    final url = context.read<LibraryRepository>().getImageUrl(_items[_center].id, maxWidth: _bgCacheWidth);
    if (url == null || url.isEmpty) return null;
    return ResizeImage(CachedNetworkImageProvider(url), width: _bgCacheWidth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipOval(
            child: Stack(
              children: [
                Positioned.fill(child: _BackgroundImage(imageProvider: _bgProvider())),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.query,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 54),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WearTheme.textSecondary),
                      ),
                    ),
                  )
                      : RotaryWheelList<LibraryItem>(
                    items: _items,
                    itemExtent: 78,
                    showScrollIndicator: false,
                    onCenteredItemChanged: (_, idx) => setState(() => _center = idx),
                    onItemTap: (item, _) => widget.onTap(item),
                    itemBuilder: (context, item, index, isCentered) {
                      return _TitleCard(title: item.name, subtitle: item.subtitle, isCentered: isCentered);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryBrowseScreen extends StatefulWidget {
  final _JellyfinHttp http;
  final String title;
  final String parentId;
  final Future<void> Function(LibraryItem item) onTap;

  const _LibraryBrowseScreen({
    required this.http,
    required this.title,
    required this.parentId,
    required this.onTap,
  });

  @override
  State<_LibraryBrowseScreen> createState() => _LibraryBrowseScreenState();
}

class _LibraryBrowseScreenState extends State<_LibraryBrowseScreen> {
  bool _loading = true;
  String? _error;

  final List<LibraryItem> _items = [];
  int _start = 0;
  bool _hasMore = true;

  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;

    try {
      setState(() => _loading = true);

      final page = await widget.http.getItemsForParent(
        parentId: widget.parentId,
        startIndex: _start,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _items.addAll(page.items);
        _start += page.items.length;
        _hasMore = _items.length < page.totalRecordCount;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('LibraryBrowse _loadMore error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = <LibraryItem>[
      ..._items,
      if (_hasMore) const LibraryItem(id: '__load_more__', name: 'Load more', type: 'Folder'),
    ];

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipOval(
            child: Stack(
              children: [
                const Positioned.fill(child: _BackgroundImage(imageProvider: null)),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 54),
                  child: _error != null
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WearTheme.textSecondary),
                      ),
                    ),
                  )
                      : RotaryWheelList<LibraryItem>(
                    items: list,
                    itemExtent: 78,
                    showScrollIndicator: false,
                    onItemTap: (item, _) async {
                      if (item.id == '__load_more__') {
                        await _loadMore();
                        return;
                      }
                      if (item.isFolder) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _LibraryBrowseScreen(
                              http: widget.http,
                              title: item.name,
                              parentId: item.id,
                              onTap: widget.onTap,
                            ),
                          ),
                        );
                        return;
                      }
                      await widget.onTap(item);
                    },
                    itemBuilder: (context, item, index, isCentered) {
                      final isLoadMore = item.id == '__load_more__';
                      return _TitleCard(
                        title: isLoadMore ? 'Load more' : item.name,
                        subtitle: isLoadMore ? null : item.subtitle,
                        isCentered: isCentered,
                      );
                    },
                  ),
                ),
                if (_loading)
                  const Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryView {
  final String id;
  final String name;
  final String? collectionType;

  const LibraryView({
    required this.id,
    required this.name,
    this.collectionType,
  });
}

class _ItemsPage {
  final List<LibraryItem> items;
  final int totalRecordCount;

  const _ItemsPage({
    required this.items,
    required this.totalRecordCount,
  });
}

class _JellyfinHttp {
  final JellyfinClientWrapper _client;

  _JellyfinHttp(this._client);

  String get _base {
    final s = _client.serverUrl ?? '';
    if (s.endsWith('/')) return s.substring(0, s.length - 1);
    return s;
  }

  Map<String, String> _headers() {
    final token = _client.accessToken ?? '';
    final deviceId = _client.deviceId ?? 'wear';
    final auth =
        'MediaBrowser Client="${JellyfinConstants.clientName}", Device="${JellyfinConstants.deviceName}", DeviceId="$deviceId", Version="${JellyfinConstants.clientVersion}", Token="$token"';

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Emby-Authorization': auth,
      'Authorization': auth,
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$_base$path');
    return query == null ? u : u.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _getJson(String path, {Map<String, String>? query}) async {
    final http = HttpClient();
    try {
      final req = await http.getUrl(_uri(path, query));
      _headers().forEach(req.headers.set);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('HTTP ${res.statusCode} $path\n$body');
      }
      return (jsonDecode(body) as Map).cast<String, dynamic>();
    } finally {
      http.close(force: true);
    }
  }

  Future<List<LibraryView>> getUserViews() async {
    final userId = _client.userId;
    if (userId == null) return [];

    final json = await _getJson('/Users/$userId/Views');
    final items = (json['Items'] as List? ?? const []);
    return items.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return LibraryView(
        id: (m['Id'] ?? '') as String,
        name: (m['Name'] ?? 'Unknown') as String,
        collectionType: m['CollectionType'] as String?,
      );
    }).toList();
  }

  Future<List<LibraryItem>> getNextUp({required int limit}) async {
    final userId = _client.userId;
    if (userId == null) return [];

    final json = await _getJson(
      '/Shows/NextUp',
      query: {
        'UserId': userId,
        'Limit': '$limit',
        'EnableUserData': 'true',
      },
    );

    final items = (json['Items'] as List? ?? const []);
    return items.map(_libraryItemFromJson).toList();
  }

  Future<List<LibraryItem>> searchItems({required String query, required int limit}) async {
    final userId = _client.userId;
    if (userId == null) return [];

    final json = await _getJson(
      '/Users/$userId/Items',
      query: {
        'SearchTerm': query,
        'Recursive': 'true',
        'Limit': '$limit',
        'EnableUserData': 'true',
      },
    );

    final items = (json['Items'] as List? ?? const []);
    return items.map(_libraryItemFromJson).toList();
  }

  Future<_ItemsPage> getItemsForParent({
    required String parentId,
    required int startIndex,
    required int limit,
  }) async {
    final userId = _client.userId;
    if (userId == null) return const _ItemsPage(items: [], totalRecordCount: 0);

    final json = await _getJson(
      '/Users/$userId/Items',
      query: {
        'ParentId': parentId,
        'Recursive': 'false',
        'StartIndex': '$startIndex',
        'Limit': '$limit',
        'SortBy': 'SortName',
        'SortOrder': 'Ascending',
        'EnableUserData': 'true',
      },
    );

    final items = (json['Items'] as List? ?? const []).map(_libraryItemFromJson).toList();
    final total = (json['TotalRecordCount'] as int?) ?? items.length;
    return _ItemsPage(items: items, totalRecordCount: total);
  }

  static LibraryItem _libraryItemFromJson(dynamic e) {
    final m = (e as Map).cast<String, dynamic>();

    return LibraryItem(
      id: (m['Id'] ?? '') as String,
      name: (m['Name'] ?? 'Unknown') as String,
      type: (m['Type'] ?? '') as String,
      seriesId: m['SeriesId'] as String?,
      seriesName: m['SeriesName'] as String?,
      albumId: m['AlbumId'] as String?,
      albumName: m['Album'] as String?,
      artistName: m['AlbumArtist'] as String?,
      indexNumber: m['IndexNumber'] as int?,
      parentIndexNumber: m['ParentIndexNumber'] as int?,
      runTimeTicks: m['RunTimeTicks'] as int?,
      overview: m['Overview'] as String?,
      productionYear: m['ProductionYear'] as int?,
      imagePrimaryTag: (m['ImageTags'] as Map?)?.cast<String, dynamic>()['Primary'] as String?,
      imageBackdropTag: (m['BackdropImageTags'] as List?)?.isNotEmpty == true
          ? ((m['BackdropImageTags'] as List).first as String?)
          : null,
      communityRating: (m['CommunityRating'] as num?)?.toDouble(),
    );
  }
}
