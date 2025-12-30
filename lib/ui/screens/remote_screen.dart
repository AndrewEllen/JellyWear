import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

import '../../core/services/ongoing_activity_service.dart';
import '../../core/theme/wear_theme.dart';
import '../../data/repositories/library_repository.dart';
import '../../navigation/app_router.dart';
import '../../state/remote_state.dart';
import '../widgets/common/rotary_scroll_wrapper.dart';
import '../widgets/remote/playback_ring.dart';
import '../widgets/remote/volume_arc.dart';
import 'media_selection_screen.dart';
import 'seek_screen.dart';

/// Main remote control screen with transport controls, playback ring, and volume arc.
///
/// Features:
/// - 3-page PageView: Remote Controls, Seek, Media Selection
/// - Page 1: Blurred background, playback ring, volume arc, controls
/// - Rotary controls volume on page 1
class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen>
    with RotaryScrollMixin<RemoteScreen> {
  late PageController _pageController;
  Timer? _volumeDeflateTimer;
  bool _volumeActive = false;
  StreamSubscription<RotaryEvent>? _volumeRotarySubscription;

  @override
  int get numberOfPages => 3;

  @override
  void initState() {
    super.initState();
    OngoingActivityService.start(title: 'Jellyfin Remote');

    _pageController = PageController(initialPage: 0);
    initRotaryScroll(_pageController);

    // Start polling playback state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemoteState>().startPolling();
    });

    // Subscribe to rotary for volume control on page 0
    _volumeRotarySubscription = rotaryEvents.listen(_onVolumeRotaryEvent);
  }

  @override
  void dispose() {
    _volumeDeflateTimer?.cancel();
    _volumeRotarySubscription?.cancel();
    disposeRotaryScroll();
    OngoingActivityService.stop();
    super.dispose();
  }

  void _onVolumeRotaryEvent(RotaryEvent event) {
    // Only handle volume on the first page (remote controls)
    if (currentPage != 0) return;

    final remoteState = context.read<RemoteState>();
    final currentVolume = remoteState.playbackState.volumeLevel;

    final delta = event.direction == RotaryDirection.clockwise ? 5 : -5;
    final newVolume = (currentVolume + delta).clamp(0, 100);

    if (newVolume != currentVolume) {
      HapticFeedback.lightImpact();
      remoteState.setVolume(newVolume);

      // Activate volume indicator
      if (!_volumeActive) {
        setState(() => _volumeActive = true);
      }
      _scheduleVolumeDeflate();
    }
  }

  void _scheduleVolumeDeflate() {
    _volumeDeflateTimer?.cancel();
    _volumeDeflateTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _volumeActive = false);
      }
    });
  }

  Future<void> _playPause() async {
    HapticFeedback.mediumImpact();
    await context.read<RemoteState>().playPause();
  }

  Future<void> _stop() async {
    HapticFeedback.mediumImpact();
    await context.read<RemoteState>().stop();
  }

  Future<void> _skipNext() async {
    HapticFeedback.mediumImpact();
    await context.read<RemoteState>().next();
  }

  Future<void> _skipPrevious() async {
    HapticFeedback.mediumImpact();
    await context.read<RemoteState>().previous();
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

  String _formatTime(int ticks) {
    final seconds = ticks ~/ 10000000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;

    if (hours > 0) {
      return '$hours:${(minutes % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Consumer<RemoteState>(
        builder: (context, remoteState, child) {
          return RotaryPageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Clear volume active when switching pages
              if (index != 0 && _volumeActive) {
                setState(() => _volumeActive = false);
              }
            },
            children: [
              // Page 1: Remote Controls
              _buildRemoteControlsPage(remoteState),
              // Page 2: Seek Screen
              const SeekScreen(),
              // Page 3: Media Selection
              const MediaSelectionScreen(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRemoteControlsPage(RemoteState remoteState) {
    final playback = remoteState.playbackState;
    final isPlaying = playback.isPlaying;
    final isMuted = playback.isMuted;
    final volumeLevel = playback.volumeLevel;
    final progress = playback.progress;
    final positionTicks = playback.positionTicks;
    final durationTicks = playback.durationTicks ?? 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background image
        _buildBackground(playback.nowPlayingItemId),

        // Playback progress ring (outer)
        IgnorePointer(
          child: PlaybackRing(
            progress: progress,
            strokeWidth: 6,
            edgePadding: 4,
          ),
        ),

        // Volume arc (top, inside playback ring) - make it non-interactive on this page
        IgnorePointer(
          child: VolumeArc(
            volumeLevel: volumeLevel,
            isMuted: isMuted,
            handleRotary: false,
            edgePadding: 14,
          ),
        ),

        // Center content
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timestamp
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(positionTicks),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _formatTime(durationTicks),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WearTheme.textSecondary,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main control buttons row: Previous, Play/Pause, Next
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: Icons.skip_previous,
                      onTap: _skipPrevious,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    _ControlButton(
                      icon: isPlaying ? Icons.pause : Icons.play_arrow,
                      onTap: _playPause,
                      size: 44,
                      highlighted: true,
                    ),
                    const SizedBox(width: 12),
                    _ControlButton(
                      icon: Icons.skip_next,
                      onTap: _skipNext,
                      size: 32,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Secondary controls row: CC, Audio, Stop
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: Icons.closed_caption,
                      onTap: _openSubtitleTracks,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    _ControlButton(
                      icon: Icons.audiotrack,
                      onTap: _openAudioTracks,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    _ControlButton(
                      icon: Icons.stop,
                      onTap: _stop,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Volume active indicator (shows when adjusting volume)
        if (_volumeActive)
          Positioned(
            top: 36,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Text(
                isMuted ? 'MUTED' : '$volumeLevel%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isMuted
                      ? WearTheme.textSecondary
                      : const Color(0xFFFFD700),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackground(String? itemId) {
    if (itemId == null) {
      return Container(color: WearTheme.background);
    }

    final libraryRepo = context.read<LibraryRepository>();
    final imageUrl = libraryRepo.getImageUrl(
      itemId,
      imageType: 'Backdrop',
      maxWidth: 400,
    );

    if (imageUrl == null) {
      return Container(color: WearTheme.background);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
              Container(color: WearTheme.background),
          placeholder: (context, url) =>
              Container(color: WearTheme.background),
        ),
        // Blur overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool highlighted;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 28,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (highlighted) {
      return Container(
        decoration: const BoxDecoration(
          color: WearTheme.jellyfinPurple,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: size),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(),
        ),
      );
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: size),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
  }
}
