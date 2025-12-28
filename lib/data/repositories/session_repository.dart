import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/prefs_keys.dart';
import '../jellyfin/jellyfin_client_wrapper.dart';
import '../models/session_device.dart';

/// Repository for managing Jellyfin sessions.
class SessionRepository {
  final JellyfinClientWrapper _client;

  SessionRepository(this._client);

  /// Gets all active sessions that support remote control.
  Future<List<SessionDevice>> getActiveSessions() async {
    try {
      final response = await _client.sessionApi?.getSessions(
        controllableByUserId: _client.userId,
      );

      final sessions = response?.data ?? [];

      return sessions
          .where((s) => s.supportsRemoteControl == true || s.supportsMediaControl == true)
          .where((s) => s.deviceId != _client.deviceId) // Exclude self
          .map((dto) => SessionDevice.fromDto(dto))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Starts playback on a session.
  Future<bool> play({
    required String sessionId,
    required List<String> itemIds,
    int? startPositionTicks,
  }) async {
    try {
      await _client.sessionApi?.play(
        sessionId: sessionId,
        itemIds: itemIds,
        playCommand: PlayCommand.playNow,
        startPositionTicks: startPositionTicks,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Queues items for playback on a session.
  Future<bool> queueNext({
    required String sessionId,
    required List<String> itemIds,
  }) async {
    try {
      await _client.sessionApi?.play(
        sessionId: sessionId,
        itemIds: itemIds,
        playCommand: PlayCommand.playNext,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Queues items at the end of the playlist.
  Future<bool> queueLast({
    required String sessionId,
    required List<String> itemIds,
  }) async {
    try {
      await _client.sessionApi?.play(
        sessionId: sessionId,
        itemIds: itemIds,
        playCommand: PlayCommand.playLast,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Saves the last used session ID.
  Future<void> saveLastSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.lastTargetSessionId, sessionId);
  }

  /// Gets the last used session ID.
  Future<String?> getLastSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.lastTargetSessionId);
  }

  /// Clears the last used session ID.
  Future<void> clearLastSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefsKeys.lastTargetSessionId);
  }
}
