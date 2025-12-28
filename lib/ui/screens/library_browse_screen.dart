import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../data/models/library_item.dart';
import '../../data/repositories/library_repository.dart';
import '../../navigation/app_router.dart';
import '../widgets/common/wear_list_view.dart';

/// Screen for browsing library items (movies, shows, albums, etc.).
class LibraryBrowseScreen extends StatefulWidget {
  final LibraryBrowseArgs? args;

  const LibraryBrowseScreen({super.key, this.args});

  @override
  State<LibraryBrowseScreen> createState() => _LibraryBrowseScreenState();
}

class _LibraryBrowseScreenState extends State<LibraryBrowseScreen> {
  bool _isLoading = true;
  final List<LibraryItem> _items = [];
  String? _errorMessage;
  LibraryRepository? _libraryRepo;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final parentId = widget.args?.parentId;
    if (parentId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No library selected';
      });
      return;
    }

    try {
      _libraryRepo = context.read<LibraryRepository>();
      final items = await _libraryRepo!.getItems(parentId: parentId);

      if (!mounted) return;

      setState(() {
        _items.clear();
        _items.addAll(items);
        _isLoading = false;
        _errorMessage = items.isEmpty ? 'No items found' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load items';
      });
    }
  }

  void _onItemTap(LibraryItem item) {
    if (item.isFolder) {
      // Navigate deeper into the folder
      Navigator.pushNamed(
        context,
        AppRoutes.libraryBrowse,
        arguments: LibraryBrowseArgs(
          parentId: item.id,
          title: item.name,
          mediaType: widget.args?.mediaType,
        ),
      );
    } else {
      // Show item details
      Navigator.pushNamed(
        context,
        AppRoutes.itemDetail,
        arguments: ItemDetailArgs(
          itemId: item.id,
          title: item.name,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.args?.title ?? 'Library';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _items.isEmpty) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: Center(
          child: Padding(
            padding: WatchShape.edgePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.folder_open_outlined,
                  size: 32,
                  color: WearTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? 'No items found',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadItems();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final padding = WatchShape.edgePadding(context);

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: [
          // Header
          _buildHeader(context, title, padding),
          // Items
          ..._items.map((item) => _buildItemTile(context, item, padding)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    LibraryItem item,
    EdgeInsets padding,
  ) {
    final imageUrl = _libraryRepo?.getImageUrl(item.id, maxWidth: 100);

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: InkWell(
            onTap: () => _onItemTap(item),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WearTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: WearTheme.surfaceVariant,
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                item.isFolder
                                    ? Icons.folder
                                    : Icons.play_circle_outline,
                                color: WearTheme.textSecondary,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                item.isFolder
                                    ? Icons.folder
                                    : Icons.play_circle_outline,
                                color: WearTheme.textSecondary,
                              ),
                            )
                          : Icon(
                              item.isFolder
                                  ? Icons.folder
                                  : Icons.play_circle_outline,
                              color: WearTheme.textSecondary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.subtitle != null)
                          Text(
                            item.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: WearTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
