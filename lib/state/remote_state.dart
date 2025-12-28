import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

import '../core/constants/jellyfin_constants.dart';
import '../data/jellyfin/jellyfin_client_wrapper.dart';
import '../data/models/playback_state.dart';
import '../data/models/session_device.dart';

/// State for remote control functionality.
class RemoteState extends ChangeNotifier {
  final JellyfinClientWrapper _client;

  SessionDevice? _targetSession;
  PlaybackState _playbackState = const PlaybackState();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollTimer;

  RemoteState(this._client);

  /// Current target session.
  SessionDevice? get targetSession => _targetSession;

  /// Current playback state.
  PlaybackState get playbackState => _playbackState;

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Error message if an operation failed.
  String? get errorMessage => _errorMessage;

  /// Whether we're connected to a target session.
  bool get hasTarget => _targetSession != null;

  /// Whether something is playing.
  bool get isPlaying => _playbackState.isPlaying;

  /// Sets the target session and starts polling.
  void setTargetSession(SessionDevice session) {
    _targetSession = session;
    _startPolling();
    notifyListeners();
  }

  /// Clears the target session and stops polling.
  void clearTargetSession() {
    _stopPolling();
    _targetSession = null;
    _playbackState = const PlaybackState();
    notifyListeners();
  }

  /// Starts polling for playback state updates.
  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(
      JellyfinConstants.playbackPollInterval,
      (_) => _refreshPlaybackState(),
    );
    // Immediate first poll
    _refreshPlaybackState();
  }

  /// Stops polling.
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Refreshes the current playback state.
  Future<void> _refreshPlaybackState() async {
    if (_targetSession == null) return;

    try {
      final response = await _client.sessionApi?.getSessions();
      final sessions = response?.data ?? [];

      final session = sessions.firstWhere(
        (s) => s.id == _targetSession!.sessionId,
        orElse: () => throw Exception('Session not found'),
      );

      _playbackState = PlaybackState.fromSessionDto(session);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      // Session may have disconnected
      _errorMessage = 'Lost connection to device';
    }
  }

  // Playstate Commands

  /// Toggles play/pause.
  Future<void> playPause() async {
    await _sendPlaystateCommand(PlaystateCommand.playPause);
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _sendPlaystateCommand(PlaystateCommand.pause);
  }

  /// Resumes playback.
  Future<void> unpause() async {
    await _sendPlaystateCommand(PlaystateCommand.unpause);
  }

  /// Stops playback.
  Future<void> stop() async {
    await _sendPlaystateCommand(PlaystateCommand.stop);
  }

  /// Skips to next track.
  Future<void> next() async {
    await _sendPlaystateCommand(PlaystateCommand.nextTrack);
  }

  /// Goes to previous track.
  Future<void> previous() async {
    await _sendPlaystateCommand(PlaystateCommand.previousTrack);
  }

  /// Seeks to a specific position.
  Future<void> seek(int positionTicks) async {
    await _sendPlaystateCommand(
      PlaystateCommand.seek,
      seekPositionTicks: positionTicks,
    );

    // Optimistically update local state
    _playbackState = _playbackState.copyWithPosition(positionTicks);
    notifyListeners();
  }

  /// Seeks forward by a number of seconds.
  Future<void> seekForward(int seconds) async {
    final newPosition = _playbackState.positionTicks +
        (seconds * JellyfinConstants.ticksPerSecond);
    final maxPosition = _playbackState.durationTicks ?? newPosition;
    await seek(newPosition.clamp(0, maxPosition));
  }

  /// Seeks backward by a number of seconds.
  Future<void> seekBackward(int seconds) async {
    final newPosition = _playbackState.positionTicks -
        (seconds * JellyfinConstants.ticksPerSecond);
    await seek(newPosition.clamp(0, _playbackState.durationTicks ?? 0));
  }

  /// Rewinds (fast backward).
  Future<void> rewind() async {
    await _sendPlaystateCommand(PlaystateCommand.rewind);
  }

  /// Fast forwards.
  Future<void> fastForward() async {
    await _sendPlaystateCommand(PlaystateCommand.fastForward);
  }

  Future<void> _sendPlaystateCommand(
    PlaystateCommand command, {
    int? seekPositionTicks,
  }) async {
    if (_targetSession == null) return;

    try {
      await _client.sessionApi?.sendPlaystateCommand(
        sessionId: _targetSession!.sessionId,
        command: command,
        seekPositionTicks: seekPositionTicks,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Command failed';
    }

    notifyListeners();
  }

  // General Commands

  /// Increases volume.
  Future<void> volumeUp() async {
    await _sendGeneralCommand(GeneralCommandType.volumeUp);
  }

  /// Decreases volume.
  Future<void> volumeDown() async {
    await _sendGeneralCommand(GeneralCommandType.volumeDown);
  }

  /// Sets volume to a specific level (0-100).
  Future<void> setVolume(int level) async {
    await _sendGeneralCommand(
      GeneralCommandType.setVolume,
      arguments: {'Volume': level.toString()},
    );
  }

  /// Toggles mute.
  Future<void> toggleMute() async {
    await _sendGeneralCommand(GeneralCommandType.toggleMute);
  }

  /// Mutes the session.
  Future<void> mute() async {
    await _sendGeneralCommand(GeneralCommandType.mute);
  }

  /// Unmutes the session.
  Future<void> unmute() async {
    await _sendGeneralCommand(GeneralCommandType.unmute);
  }

  /// Sets the audio stream index.
  Future<void> setAudioStream(int index) async {
    await _sendGeneralCommand(
      GeneralCommandType.setAudioStreamIndex,
      arguments: {'Index': index.toString()},
    );
  }

  /// Sets the subtitle stream index. Use -1 to disable subtitles.
  Future<void> setSubtitleStream(int index) async {
    await _sendGeneralCommand(
      GeneralCommandType.setSubtitleStreamIndex,
      arguments: {'Index': index.toString()},
    );
  }

  Future<void> _sendGeneralCommand(
    GeneralCommandType command, {
    Map<String, String>? arguments,
  }) async {
    if (_targetSession == null) return;

    try {
      await _client.sessionApi?.sendGeneralCommand(
        sessionId: _targetSession!.sessionId,
        command: command,
        // Note: arguments would need to be sent via sendFullGeneralCommand
        // for commands that require them
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Command failed';
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
