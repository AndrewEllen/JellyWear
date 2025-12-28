import 'package:flutter/foundation.dart';

import '../data/models/session_device.dart';
import '../data/repositories/session_repository.dart';

/// State for managing target session selection.
class SessionState extends ChangeNotifier {
  final SessionRepository _repository;

  List<SessionDevice> _sessions = [];
  SessionDevice? _targetSession;
  bool _isLoading = false;
  String? _errorMessage;

  SessionState(this._repository);

  /// Available sessions.
  List<SessionDevice> get sessions => _sessions;

  /// Currently selected target session.
  SessionDevice? get targetSession => _targetSession;

  /// Whether sessions are loading.
  bool get isLoading => _isLoading;

  /// Error message if loading failed.
  String? get errorMessage => _errorMessage;

  /// Whether a target session is selected.
  bool get hasTarget => _targetSession != null;

  /// Refreshes the list of active sessions.
  Future<void> refreshSessions() async {
    _setLoading(true);

    try {
      _sessions = await _repository.getActiveSessions();
      _errorMessage = null;

      // Try to restore last used session
      if (_targetSession == null) {
        await _tryRestoreLastSession();
      } else {
        // Verify current target is still available
        final stillAvailable = _sessions.any((s) => s.sessionId == _targetSession!.sessionId);
        if (!stillAvailable) {
          _targetSession = null;
          await _repository.clearLastSession();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load sessions';
    }

    _setLoading(false);
  }

  /// Sets the target session for remote control.
  Future<void> setTargetSession(SessionDevice session) async {
    _targetSession = session;
    await _repository.saveLastSession(session.sessionId);
    notifyListeners();
  }

  /// Clears the target session.
  Future<void> clearTargetSession() async {
    _targetSession = null;
    await _repository.clearLastSession();
    notifyListeners();
  }

  /// Starts playback of items on the target session.
  Future<bool> playOnTarget(List<String> itemIds) async {
    if (_targetSession == null) return false;

    return _repository.play(
      sessionId: _targetSession!.sessionId,
      itemIds: itemIds,
    );
  }

  /// Queues items next on the target session.
  Future<bool> queueNextOnTarget(List<String> itemIds) async {
    if (_targetSession == null) return false;

    return _repository.queueNext(
      sessionId: _targetSession!.sessionId,
      itemIds: itemIds,
    );
  }

  /// Tries to restore the last used session.
  Future<void> _tryRestoreLastSession() async {
    final lastSessionId = await _repository.getLastSessionId();
    if (lastSessionId == null) return;

    final session = _sessions.where((s) => s.sessionId == lastSessionId).firstOrNull;
    if (session != null) {
      _targetSession = session;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
