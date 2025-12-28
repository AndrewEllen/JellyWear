import 'package:flutter/foundation.dart';

import '../data/jellyfin/jellyfin_client_wrapper.dart';
import '../data/jellyfin/server_discovery.dart';
import '../data/models/server_info.dart';
import '../data/repositories/auth_repository.dart';

/// Connection status enum.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Main application state provider.
class AppState extends ChangeNotifier {
  final JellyfinClientWrapper _client;
  final AuthRepository _authRepository;
  final ServerDiscovery _serverDiscovery;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  ServerInfo? _currentServer;
  String? _userName;

  AppState({
    required JellyfinClientWrapper client,
    required AuthRepository authRepository,
    ServerDiscovery? serverDiscovery,
  })  : _client = client,
        _authRepository = authRepository,
        _serverDiscovery = serverDiscovery ?? ServerDiscovery();

  /// Current connection status.
  ConnectionStatus get status => _status;

  /// Error message if status is error.
  String? get errorMessage => _errorMessage;

  /// Currently connected server info.
  ServerInfo? get currentServer => _currentServer;

  /// Current user name.
  String? get userName => _userName;

  /// Whether the app is connected and authenticated.
  bool get isAuthenticated => _status == ConnectionStatus.connected;

  /// The Jellyfin client wrapper.
  JellyfinClientWrapper get client => _client;

  /// Server discovery instance.
  ServerDiscovery get serverDiscovery => _serverDiscovery;

  /// Attempts to auto-connect using stored credentials.
  Future<bool> tryAutoConnect() async {
    _setStatus(ConnectionStatus.connecting);

    try {
      final success = await _authRepository.tryRestoreSession();

      if (success) {
        _userName = await _authRepository.getCurrentUserName();
        final serverUrl = await _authRepository.getCurrentServerUrl();
        if (serverUrl != null) {
          _currentServer = ServerInfo(
            id: '',
            name: 'Server',
            address: serverUrl,
          );
        }
        _setStatus(ConnectionStatus.connected);
        return true;
      } else {
        _setStatus(ConnectionStatus.disconnected);
        return false;
      }
    } catch (e) {
      _setError('Failed to restore session');
      return false;
    }
  }

  /// Connects to a server and logs in.
  Future<bool> login({
    required ServerInfo server,
    required String username,
    required String password,
  }) async {
    _setStatus(ConnectionStatus.connecting);
    _errorMessage = null;

    try {
      final success = await _authRepository.login(
        serverUrl: server.address,
        username: username,
        password: password,
      );

      if (success) {
        _currentServer = server;
        _userName = username;

        // Save server to recent list
        await _authRepository.saveServer(server);

        _setStatus(ConnectionStatus.connected);
        return true;
      } else {
        _setError('Invalid username or password');
        return false;
      }
    } catch (e) {
      _setError('Connection failed: ${e.toString()}');
      return false;
    }
  }

  /// Logs out and disconnects.
  Future<void> logout() async {
    await _authRepository.logout();
    _currentServer = null;
    _userName = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  /// Gets saved servers.
  Future<List<ServerInfo>> getSavedServers() {
    return _authRepository.getSavedServers();
  }

  /// Discovers servers on the local network.
  Future<List<ServerInfo>> discoverServers({Duration? timeout}) {
    return _serverDiscovery.discover(timeout: timeout ?? const Duration(seconds: 5));
  }

  /// Stream of discovered servers.
  Stream<List<ServerInfo>> get discoveredServersStream => _serverDiscovery.servers;

  void _setStatus(ConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ConnectionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _serverDiscovery.dispose();
    super.dispose();
  }
}
