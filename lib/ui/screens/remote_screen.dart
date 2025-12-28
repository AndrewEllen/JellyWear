import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/ongoing_activity_service.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../navigation/app_router.dart';
import '../widgets/common/wear_list_view.dart';

/// Main remote control screen with transport controls and now playing info.
class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  bool _isPlaying = false;
  bool _isMuted = false;
  String _nowPlayingTitle = 'Nothing Playing';
  String _nowPlayingSubtitle = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    OngoingActivityService.start(title: 'Jellyfin Remote');
    _startPolling();
  }

  @override
  void dispose() {
    OngoingActivityService.stop();
    super.dispose();
  }

  void _startPolling() {
    // TODO: Start polling playback state from Jellyfin API
  }

  Future<void> _playPause() async {
    HapticFeedback.mediumImpact();
    // TODO: Send playPause command to Jellyfin
    setState(() => _isPlaying = !_isPlaying);
  }

  Future<void> _stop() async {
    HapticFeedback.mediumImpact();
    // TODO: Send stop command to Jellyfin
    setState(() => _isPlaying = false);
  }

  Future<void> _previous() async {
    HapticFeedback.mediumImpact();
    // TODO: Send previousTrack command to Jellyfin
  }

  Future<void> _next() async {
    HapticFeedback.mediumImpact();
    // TODO: Send nextTrack command to Jellyfin
  }

  Future<void> _volumeUp() async {
    HapticFeedback.lightImpact();
    // TODO: Send volumeUp command to Jellyfin
  }

  Future<void> _volumeDown() async {
    HapticFeedback.lightImpact();
    // TODO: Send volumeDown command to Jellyfin
  }

  Future<void> _toggleMute() async {
    HapticFeedback.mediumImpact();
    // TODO: Send toggleMute command to Jellyfin
    setState(() => _isMuted = !_isMuted);
  }

  void _openSeek() {
    Navigator.pushNamed(context, AppRoutes.seek);
  }

  void _openAudioTracks() {
    Navigator.pushNamed(
      context,
      AppRoutes.trackPicker,
      arguments: const TrackPickerArgs(isAudio: true),
    );
  }

  void _openSubtitleTracks() {
    Navigator.pushNamed(
      context,
      AppRoutes.trackPicker,
      arguments: const TrackPickerArgs(isAudio: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: [
          // Now playing info
          _buildNowPlaying(context, padding),
          // Transport controls
          _buildTransportControls(context, padding),
          // Volume controls
          _buildVolumeControls(context, padding),
          // Track selection
          _buildTrackControls(context, padding),
        ],
      ),
    );
  }

  Widget _buildNowPlaying(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: GestureDetector(
            onTap: _openSeek,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thumbnail placeholder
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: WearTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: WearTheme.textSecondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _nowPlayingTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_nowPlayingSubtitle.isNotEmpty)
                  Text(
                    _nowPlayingSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransportControls(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _previous,
                icon: const Icon(Icons.skip_previous, size: 32),
              ),
              Container(
                decoration: BoxDecoration(
                  color: WearTheme.jellyfinPurple,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _playPause,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 36,
                  ),
                ),
              ),
              IconButton(
                onPressed: _next,
                icon: const Icon(Icons.skip_next, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControls(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _volumeDown,
                icon: const Icon(Icons.volume_down, size: 28),
              ),
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 28,
                  color: _isMuted ? WearTheme.textSecondary : null,
                ),
              ),
              IconButton(
                onPressed: _volumeUp,
                icon: const Icon(Icons.volume_up, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackControls(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TrackButton(
                icon: Icons.audiotrack,
                label: 'Audio',
                onTap: _openAudioTracks,
              ),
              _TrackButton(
                icon: Icons.closed_caption,
                label: 'Subs',
                onTap: _openSubtitleTracks,
              ),
              _TrackButton(
                icon: Icons.stop,
                label: 'Stop',
                onTap: _stop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TrackButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
