import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../data/models/library_item.dart';
import '../../data/repositories/library_repository.dart';
import '../../navigation/app_router.dart';
import '../../state/app_state.dart';
import '../widgets/common/wear_list_view.dart';

/// Screen for selecting which library type to browse (Movies, TV, Music).
class LibraryPickerScreen extends StatefulWidget {
  const LibraryPickerScreen({super.key});

  @override
  State<LibraryPickerScreen> createState() => _LibraryPickerScreenState();
}

class _LibraryPickerScreenState extends State<LibraryPickerScreen> {
  bool _isLoading = true;
  List<LibraryView> _libraries = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLibraries();
  }

  Future<void> _loadLibraries() async {
    try {
      final libraryRepo = context.read<LibraryRepository>();
      final appState = context.read<AppState>();

      // Check if we're authenticated
      if (!appState.isAuthenticated) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not authenticated';
        });
        return;
      }

      final libraries = await libraryRepo.getLibraries();

      if (!mounted) return;

      setState(() {
        _libraries = libraries;
        _isLoading = false;
        _errorMessage = libraries.isEmpty ? 'No libraries found' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load: $e';
      });
    }
  }

  IconData _getIconForCollectionType(String? collectionType) {
    switch (collectionType?.toLowerCase()) {
      case 'movies':
        return Icons.movie_outlined;
      case 'tvshows':
        return Icons.tv_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'books':
        return Icons.book_outlined;
      case 'photos':
        return Icons.photo_library_outlined;
      case 'homevideos':
        return Icons.videocam_outlined;
      case 'boxsets':
        return Icons.folder_special_outlined;
      case 'playlists':
        return Icons.playlist_play_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  void _navigateToLibrary(LibraryView library) {
    Navigator.pushNamed(
      context,
      AppRoutes.libraryBrowse,
      arguments: LibraryBrowseArgs(
        parentId: library.id,
        title: library.name,
        mediaType: library.collectionType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _libraries.isEmpty) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: Center(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.folder_off_outlined,
                  size: 32,
                  color: WearTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'No libraries',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadLibraries();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: _libraries
            .map((library) => _LibraryTypeItem(
                  icon: _getIconForCollectionType(library.collectionType),
                  label: library.name,
                  onTap: () => _navigateToLibrary(library),
                  padding: padding,
                ))
            .toList(),
      ),
    );
  }
}

class _LibraryTypeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const _LibraryTypeItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: WearTheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 36,
                    color: WearTheme.jellyfinPurple,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
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
