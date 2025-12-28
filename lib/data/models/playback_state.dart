import '../../core/constants/jellyfin_constants.dart';

/// Model representing the current playback state of a session.
class PlaybackState {
  final int positionTicks;
  final int? durationTicks;
  final bool isPaused;
  final bool isMuted;
  final int volumeLevel;
  final String? nowPlayingItemId;
  final String? nowPlayingItemName;
  final String? nowPlayingItemType;
  final String? nowPlayingArtist;
  final String? nowPlayingAlbum;
  final List<MediaStream> audioStreams;
  final List<MediaStream> subtitleStreams;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final String? playMethod;

  const PlaybackState({
    this.positionTicks = 0,
    this.durationTicks,
    this.isPaused = true,
    this.isMuted = false,
    this.volumeLevel = 100,
    this.nowPlayingItemId,
    this.nowPlayingItemName,
    this.nowPlayingItemType,
    this.nowPlayingArtist,
    this.nowPlayingAlbum,
    this.audioStreams = const [],
    this.subtitleStreams = const [],
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.playMethod,
  });

  /// Whether something is currently playing.
  bool get isPlaying => !isPaused && nowPlayingItemId != null;

  /// Whether there is any media loaded.
  bool get hasMedia => nowPlayingItemId != null;

  /// Progress as a value from 0.0 to 1.0.
  double get progress {
    if (durationTicks == null || durationTicks! <= 0) return 0;
    return positionTicks / durationTicks!;
  }

  /// Current position in seconds.
  int get positionSeconds => positionTicks ~/ JellyfinConstants.ticksPerSecond;

  /// Total duration in seconds.
  int? get durationSeconds => durationTicks != null
      ? durationTicks! ~/ JellyfinConstants.ticksPerSecond
      : null;

  /// Formatted position string (e.g., "1:23:45" or "23:45").
  String get formattedPosition => _formatDuration(positionSeconds);

  /// Formatted duration string.
  String get formattedDuration => _formatDuration(durationSeconds ?? 0);

  /// Formatted remaining time string.
  String get formattedRemaining {
    final remaining = (durationSeconds ?? 0) - positionSeconds;
    return '-${_formatDuration(remaining)}';
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a PlaybackState from session info DTO.
  factory PlaybackState.fromSessionDto(dynamic sessionDto) {
    final playState = sessionDto.playState;
    final nowPlaying = sessionDto.nowPlayingItem;

    List<MediaStream> audioStreams = [];
    List<MediaStream> subtitleStreams = [];

    if (nowPlaying?.mediaStreams != null) {
      for (final stream in nowPlaying.mediaStreams!) {
        final mediaStream = MediaStream.fromDto(stream);
        if (stream.type == 'Audio') {
          audioStreams.add(mediaStream);
        } else if (stream.type == 'Subtitle') {
          subtitleStreams.add(mediaStream);
        }
      }
    }

    return PlaybackState(
      positionTicks: playState?.positionTicks ?? 0,
      durationTicks: nowPlaying?.runTimeTicks,
      isPaused: playState?.isPaused ?? true,
      isMuted: playState?.isMuted ?? false,
      volumeLevel: playState?.volumeLevel ?? 100,
      nowPlayingItemId: nowPlaying?.id,
      nowPlayingItemName: nowPlaying?.name,
      nowPlayingItemType: nowPlaying?.type,
      nowPlayingArtist: nowPlaying?.albumArtist ??
          (nowPlaying?.artists?.isNotEmpty == true ? nowPlaying.artists!.first : null),
      nowPlayingAlbum: nowPlaying?.album,
      audioStreams: audioStreams,
      subtitleStreams: subtitleStreams,
      audioStreamIndex: playState?.audioStreamIndex,
      subtitleStreamIndex: playState?.subtitleStreamIndex,
      playMethod: playState?.playMethod,
    );
  }

  /// Returns a copy with updated position.
  PlaybackState copyWithPosition(int newPositionTicks) {
    return PlaybackState(
      positionTicks: newPositionTicks,
      durationTicks: durationTicks,
      isPaused: isPaused,
      isMuted: isMuted,
      volumeLevel: volumeLevel,
      nowPlayingItemId: nowPlayingItemId,
      nowPlayingItemName: nowPlayingItemName,
      nowPlayingItemType: nowPlayingItemType,
      nowPlayingArtist: nowPlayingArtist,
      nowPlayingAlbum: nowPlayingAlbum,
      audioStreams: audioStreams,
      subtitleStreams: subtitleStreams,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      playMethod: playMethod,
    );
  }

  @override
  String toString() =>
      'PlaybackState(item: $nowPlayingItemName, position: $formattedPosition/$formattedDuration, paused: $isPaused)';
}

/// Represents an audio or subtitle stream.
class MediaStream {
  final int index;
  final String type;
  final String? codec;
  final String? language;
  final String? displayTitle;
  final bool isDefault;
  final bool isForced;
  final bool isExternal;
  final int? channels;

  const MediaStream({
    required this.index,
    required this.type,
    this.codec,
    this.language,
    this.displayTitle,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
    this.channels,
  });

  /// User-friendly display name.
  String get name {
    if (displayTitle != null && displayTitle!.isNotEmpty) {
      return displayTitle!;
    }

    final parts = <String>[];
    if (language != null) parts.add(language!);
    if (codec != null) parts.add(codec!.toUpperCase());
    if (channels != null && type == 'Audio') {
      parts.add('${channels}ch');
    }
    if (isDefault) parts.add('Default');
    if (isForced) parts.add('Forced');

    return parts.isNotEmpty ? parts.join(' • ') : 'Track ${index + 1}';
  }

  factory MediaStream.fromDto(dynamic dto) {
    return MediaStream(
      index: dto.index ?? 0,
      type: dto.type ?? '',
      codec: dto.codec,
      language: dto.language,
      displayTitle: dto.displayTitle,
      isDefault: dto.isDefault ?? false,
      isForced: dto.isForced ?? false,
      isExternal: dto.isExternal ?? false,
      channels: dto.channels,
    );
  }

  @override
  String toString() => 'MediaStream(index: $index, type: $type, name: $name)';
}
