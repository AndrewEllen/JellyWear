/// SharedPreferences key constants for persistent storage.
abstract class PrefsKeys {
  // Server connection
  static const String serverUrl = 'server_url';
  static const String serverId = 'server_id';
  static const String serverName = 'server_name';
  static const String savedServers = 'saved_servers';

  // Authentication
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String deviceId = 'device_id';

  // Session
  static const String lastTargetSessionId = 'last_target_session';

  // Settings
  static const String hapticFeedbackEnabled = 'haptic_feedback_enabled';
}
