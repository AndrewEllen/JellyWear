import 'package:flutter/material.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../navigation/app_router.dart';
import '../widgets/common/wear_list_view.dart';

/// Screen for selecting a target Jellyfin session to control.
class SessionPickerScreen extends StatefulWidget {
  const SessionPickerScreen({super.key});

  @override
  State<SessionPickerScreen> createState() => _SessionPickerScreenState();
}

class _SessionPickerScreenState extends State<SessionPickerScreen> {
  bool _isLoading = true;
  final List<_SessionDevice> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    // TODO: Load active sessions from Jellyfin API
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      // TODO: Populate with actual sessions from API
    });
  }

  void _selectSession(_SessionDevice session) {
    // TODO: Store selected session and navigate to remote
    Navigator.pushNamed(context, AppRoutes.remote);
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_sessions.isEmpty) {
      return Scaffold(
        backgroundColor: WearTheme.background,
        body: Center(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.devices_outlined,
                  size: 32,
                  color: WearTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Devices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'No active Jellyfin\nclients found',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _loadSessions,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: [
          // Header
          _buildHeader(context, padding),
          // Sessions
          ..._sessions.map((session) => _buildSessionTile(context, session, padding)),
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
                Icons.devices_outlined,
                size: 28,
                color: WearTheme.jellyfinPurple,
              ),
              const SizedBox(height: 8),
              Text(
                'Select Device',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    _SessionDevice session,
    EdgeInsets padding,
  ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: InkWell(
            onTap: () => _selectSession(session),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WearTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    session.icon,
                    size: 28,
                    color: WearTheme.jellyfinPurple,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.deviceName,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          session.client,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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

class _SessionDevice {
  final String sessionId;
  final String deviceName;
  final String client;
  final IconData icon;

  _SessionDevice({
    required this.sessionId,
    required this.deviceName,
    required this.client,
    required this.icon,
  });
}
