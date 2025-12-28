import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/constants/jellyfin_constants.dart';
import '../models/server_info.dart';

/// Discovers Jellyfin servers on the local network via UDP broadcast.
class ServerDiscovery {
  RawDatagramSocket? _socket;
  final _discoveredServers = <String, ServerInfo>{};
  final _controller = StreamController<List<ServerInfo>>.broadcast();

  /// Stream of discovered servers.
  Stream<List<ServerInfo>> get servers => _controller.stream;

  /// Current list of discovered servers.
  List<ServerInfo> get currentServers => _discoveredServers.values.toList();

  /// Starts server discovery.
  /// Returns a Future that completes when discovery timeout is reached.
  Future<List<ServerInfo>> discover({
    Duration timeout = JellyfinConstants.discoveryTimeout,
  }) async {
    _discoveredServers.clear();

    try {
      // Bind to any available port for receiving responses
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      _socket!.broadcastEnabled = true;

      // Listen for responses
      _socket!.listen(_handleResponse);

      // Send probe to broadcast address
      final broadcastAddress = InternetAddress('255.255.255.255');

      for (final probe in JellyfinConstants.discoveryProbeStrings) {
        final data = utf8.encode(probe);
        _socket!.send(data, broadcastAddress, JellyfinConstants.discoveryPort);
      }

      // Wait for timeout
      await Future.delayed(timeout);
    } catch (e) {
      // Discovery failed, but that's okay - user can enter manually
    } finally {
      _socket?.close();
      _socket = null;
    }

    return currentServers;
  }

  void _handleResponse(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final datagram = _socket?.receive();
    if (datagram == null) return;

    try {
      final response = utf8.decode(datagram.data);
      final json = jsonDecode(response) as Map<String, dynamic>;

      final server = ServerInfo.fromDiscoveryJson(json);

      if (server.id.isNotEmpty && server.address.isNotEmpty) {
        if (!_discoveredServers.containsKey(server.id)) {
          _discoveredServers[server.id] = server;
          _controller.add(currentServers);
        }
      }
    } catch (e) {
      // Invalid response, ignore
    }
  }

  /// Validates that a server URL is reachable and returns server info.
  static Future<ServerInfo?> validateServer(String url) async {
    try {
      // Normalize URL
      String normalizedUrl = url.trim();
      if (!normalizedUrl.startsWith('http://') &&
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'http://$normalizedUrl';
      }

      // Remove trailing slash
      if (normalizedUrl.endsWith('/')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
      }

      // Try to fetch server info
      final uri = Uri.parse('$normalizedUrl/System/Info/Public');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        return ServerInfo(
          id: json['Id'] as String? ?? '',
          name: json['ServerName'] as String? ?? 'Jellyfin Server',
          address: normalizedUrl,
        );
      }
    } catch (e) {
      // Server not reachable
    }

    return null;
  }

  /// Disposes resources.
  void dispose() {
    _socket?.close();
    _controller.close();
  }
}
