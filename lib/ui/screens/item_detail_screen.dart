import 'package:flutter/material.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../navigation/app_router.dart';
import '../widgets/common/wear_list_view.dart';

/// Screen showing details of a media item with play option.
class ItemDetailScreen extends StatefulWidget {
  final ItemDetailArgs? args;

  const ItemDetailScreen({super.key, this.args});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isLoading = true;
  _ItemDetails? _item;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    // TODO: Load item details from Jellyfin API
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      // TODO: Populate with actual item from API
      _item = _ItemDetails(
        id: widget.args?.itemId ?? '',
        name: widget.args?.title ?? 'Unknown',
        overview: 'Item description will appear here.',
        runtime: '1h 30m',
        year: '2024',
      );
    });
  }

  Future<void> _playItem() async {
    final itemId = widget.args?.itemId ?? '';
    final itemName = _item?.name ?? widget.args?.title ?? 'Unknown';

    if (itemId.isEmpty) {
      return;
    }

    // Navigate to session picker with the item to play
    Navigator.pushNamed(
      context,
      AppRoutes.sessionPicker,
      arguments: SessionPickerArgs(
        itemIdToPlay: itemId,
        itemName: itemName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_item == null) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: Center(
          child: Text(
            'Item not found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final padding = WatchShape.edgePadding(context);

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: [
          // Title and poster
          _buildHeader(context, padding),
          // Play button
          _buildPlayButton(context, padding),
          // Details
          _buildDetails(context, padding),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poster placeholder
              Container(
                width: 60,
                height: 90,
                decoration: BoxDecoration(
                  color: WearTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.movie_outlined,
                  color: WearTheme.textSecondary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _item!.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${_item!.year} • ${_item!.runtime}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: ElevatedButton.icon(
            onPressed: _playItem,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WearTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _item!.overview,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemDetails {
  final String id;
  final String name;
  final String overview;
  final String runtime;
  final String year;
  final String? imageUrl;

  _ItemDetails({
    required this.id,
    required this.name,
    required this.overview,
    required this.runtime,
    required this.year,
    this.imageUrl,
  });
}
