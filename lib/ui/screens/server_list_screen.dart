import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../data/models/server_info.dart';
import '../../navigation/app_router.dart';
import '../../state/app_state.dart';
import '../widgets/common/wear_list_view.dart';

/// Screen showing discovered and saved servers.
class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  bool _isDiscovering = false;
  List<ServerInfo> _discoveredServers = [];
  List<ServerInfo> _savedServers = [];
  StreamSubscription<List<ServerInfo>>? _discoverySubscription;

  @override
  void initState() {
    super.initState();
    _loadSavedServers();
    _startDiscovery();
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedServers() async {
    final appState = context.read<AppState>();
    final saved = await appState.getSavedServers();
    if (mounted) {
      setState(() => _savedServers = saved);
    }
  }

  Future<void> _startDiscovery() async {
    setState(() => _isDiscovering = true);

    final appState = context.read<AppState>();

    // Listen to discovery stream for real-time updates
    _discoverySubscription?.cancel();
    _discoverySubscription = appState.discoveredServersStream.listen((servers) {
      if (mounted) {
        setState(() => _discoveredServers = servers);
      }
    });

    // Run discovery
    final servers = await appState.discoverServers(
      timeout: const Duration(seconds: 3),
    );

    if (!mounted) return;

    setState(() {
      _discoveredServers = servers;
      _isDiscovering = false;
    });
  }

  void _openManualEntry() {
    Navigator.pushNamed(context, AppRoutes.manualServer);
  }

  void _selectServer(ServerInfo server) {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: LoginScreenArgs(
        serverUrl: server.address,
        serverName: server.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);

    // Combine saved and discovered servers, removing duplicates
    final allServers = <String, ServerInfo>{};
    for (final server in _savedServers) {
      allServers[server.address] = server;
    }
    for (final server in _discoveredServers) {
      allServers[server.address] = server;
    }

    final items = <Widget>[
      // Header
      _buildHeader(context, padding),
      // All servers
      ...allServers.values.map(
        (server) => _buildServerTile(context, server, padding),
      ),
      // Manual entry option
      _buildManualEntry(context, padding),
    ];

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: _isDiscovering && allServers.isEmpty
          ? _buildLoadingState(context)
          : WearListView(children: items),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            'Searching...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WearTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dns_outlined,
                size: 32,
                color: WearTheme.jellyfinPurple,
              ),
              const SizedBox(height: 8),
              Text(
                'Select Server',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_isDiscovering) ...[
                const SizedBox(height: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerTile(
    BuildContext context,
    ServerInfo server,
    EdgeInsets padding,
  ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: InkWell(
            onTap: () => _selectServer(server),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WearTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    server.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    server.address,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntry(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: InkWell(
            onTap: _openManualEntry,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: WearTheme.surfaceVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Enter URL',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

