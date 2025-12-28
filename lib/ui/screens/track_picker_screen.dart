import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../navigation/app_router.dart';
import '../widgets/common/wear_list_view.dart';

/// Screen for selecting audio or subtitle tracks.
class TrackPickerScreen extends StatefulWidget {
  final TrackPickerArgs? args;

  const TrackPickerScreen({super.key, this.args});

  @override
  State<TrackPickerScreen> createState() => _TrackPickerScreenState();
}

class _TrackPickerScreenState extends State<TrackPickerScreen> {
  bool _isLoading = true;
  final List<_Track> _tracks = [];
  int _selectedIndex = 0;

  bool get isAudio => widget.args?.isAudio ?? true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    // TODO: Load tracks from current playback state
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      // TODO: Populate with actual tracks from playback state
      if (!isAudio) {
        // Add "None" option for subtitles
        _tracks.add(_Track(index: -1, name: 'None', language: ''));
      }
    });
  }

  Future<void> _selectTrack(_Track track) async {
    HapticFeedback.mediumImpact();

    setState(() => _selectedIndex = track.index);

    // TODO: Send track selection command to Jellyfin
    // For audio: setAudioStreamIndex
    // For subtitles: setSubtitleStreamIndex

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);
    final title = isAudio ? 'Audio' : 'Subtitles';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: Center(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAudio ? Icons.audiotrack : Icons.closed_caption,
                  size: 32,
                  color: WearTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No $title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'No tracks available',
                  style: Theme.of(context).textTheme.bodySmall,
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
        children: [
          // Header
          _buildHeader(context, title, padding),
          // Tracks
          ..._tracks.map((track) => _buildTrackTile(context, track, padding)),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAudio ? Icons.audiotrack : Icons.closed_caption,
                size: 28,
                color: WearTheme.jellyfinPurple,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackTile(
    BuildContext context,
    _Track track,
    EdgeInsets padding,
  ) {
    final isSelected = track.index == _selectedIndex;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: InkWell(
            onTap: () => _selectTrack(track),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? WearTheme.jellyfinPurple.withOpacity(0.2) : WearTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: WearTheme.jellyfinPurple, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      size: 24,
                      color: WearTheme.jellyfinPurple,
                    )
                  else
                    const Icon(
                      Icons.circle_outlined,
                      size: 24,
                      color: WearTheme.textSecondary,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.language.isNotEmpty)
                          Text(
                            track.language,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
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

class _Track {
  final int index;
  final String name;
  final String language;

  _Track({
    required this.index,
    required this.name,
    required this.language,
  });
}
