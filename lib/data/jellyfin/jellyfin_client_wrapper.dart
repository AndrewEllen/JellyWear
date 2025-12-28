import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/jellyfin_constants.dart';
import '../../core/constants/prefs_keys.dart';

/// Wrapper around the jellyfin_dart client with authentication management.
class JellyfinClientWrapper {
  JellyfinDart? _client;
  String? _serverUrl;
  String? _accessToken;
  String? _userId;
  String? _deviceId;

  /// The underlying Jellyfin client.
  JellyfinDart? get client => _client;

  /// Whether the client is initialized and authenticated.
  bool get isAuthenticated => _client != null && _accessToken != null;

  /// Current server URL.
  String? get serverUrl => _serverUrl;

  /// Current user ID.
  String? get userId => _userId;

  /// Current access token.
  String? get accessToken => _accessToken;

  /// Device ID for this app instance.
  String? get deviceId => _deviceId;

  /// Initializes the client for a server URL.
  Future<void> initialize(String serverUrl) async {
    _serverUrl = serverUrl;
    _client = JellyfinDart(basePathOverride: serverUrl);

    // Get or create device ID
    _deviceId = await _getOrCreateDeviceId();
  }

  /// Sets the authentication token after login.
  void setAuthentication({
    required String accessToken,
    required String userId,
  }) {
    _accessToken = accessToken;
    _userId = userId;

    if (_client != null && _deviceId != null) {
      _client!.setMediaBrowserAuth(
        deviceId: _deviceId!,
        version: JellyfinConstants.clientVersion,
        token: accessToken,
        device: JellyfinConstants.deviceName,
        client: JellyfinConstants.clientName,
      );
    }
  }

  /// Authenticates with username and password.
  Future<AuthenticationResult?> login(String username, String password) async {
    if (_client == null) {
      throw StateError('Client not initialized. Call initialize() first.');
    }

    try {
      // Set up unauthenticated header for login
      _client!.setMediaBrowserAuth(
        deviceId: _deviceId!,
        version: JellyfinConstants.clientVersion,
        device: JellyfinConstants.deviceName,
        client: JellyfinConstants.clientName,
      );

      final response = await _client!.getUserApi().authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName(
          username: username,
          pw: password,
        ),
      );

      if (response.data != null) {
        final result = response.data!;
        final token = result.accessToken;
        final userId = result.user?.id;

        if (token != null && userId != null) {
          setAuthentication(accessToken: token, userId: userId);
          return result;
        }
      }
    } catch (e) {
      rethrow;
    }

    return null;
  }

  /// Logs out and clears authentication.
  Future<void> logout() async {
    _accessToken = null;
    _userId = null;
    _client = null;
    _serverUrl = null;
  }

  /// Gets or creates a persistent device ID.
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(PrefsKeys.deviceId);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(PrefsKeys.deviceId, deviceId);
    }

    return deviceId;
  }

  // API accessors

  /// User API for authentication.
  UserApi? get userApi => _client?.getUserApi();

  /// Session API for remote control.
  SessionApi? get sessionApi => _client?.getSessionApi();

  /// Items API for library browsing.
  ItemsApi? get itemsApi => _client?.getItemsApi();

  /// User Library API for user-specific items.
  UserLibraryApi? get userLibraryApi => _client?.getUserLibraryApi();

  /// Library API for library views.
  LibraryApi? get libraryApi => _client?.getLibraryApi();

  /// Image API for poster URLs.
  ImageApi? get imageApi => _client?.getImageApi();

  /// Constructs an image URL for an item.
  String? getImageUrl(
    String itemId, {
    ImageType imageType = ImageType.primary,
    int? maxWidth,
    int? maxHeight,
  }) {
    if (_serverUrl == null) return null;

    final params = <String, String>{};
    if (maxWidth != null) params['maxWidth'] = maxWidth.toString();
    if (maxHeight != null) params['maxHeight'] = maxHeight.toString();

    final queryString =
        params.isNotEmpty ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';

    return '$_serverUrl/Items/$itemId/Images/${imageType.name}$queryString';
  }
}
