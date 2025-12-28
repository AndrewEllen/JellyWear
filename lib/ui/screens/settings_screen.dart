import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../data/repositories/settings_repository.dart';
import '../../navigation/app_router.dart';
import '../../state/app_state.dart';
import '../widgets/common/wear_list_view.dart';

/// Settings screen for app configuration.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsRepo = context.read<SettingsRepository>();
    final haptic = await settingsRepo.getHapticFeedbackEnabled();
    if (mounted) {
      setState(() => _hapticEnabled = haptic);
    }
  }

  Future<void> _toggleHaptic(bool value) async {
    setState(() => _hapticEnabled = value);
    final settingsRepo = context.read<SettingsRepository>();
    await settingsRepo.setHapticFeedbackEnabled(value);
  }

  Future<void> _logout() async {
    final appState = context.read<AppState>();
    await appState.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.serverList,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: [
          // Header
          _buildHeader(context, padding),
          // Haptic feedback toggle
          _buildHapticToggle(context, padding),
          // Server info
          _buildServerInfo(context, padding, appState),
          // Logout
          _buildLogout(context, padding),
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
                Icons.settings_outlined,
                size: 28,
                color: WearTheme.jellyfinPurple,
              ),
              const SizedBox(height: 8),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHapticToggle(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: WearTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Haptic',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Vibration feedback',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Switch(
                  value: _hapticEnabled,
                  onChanged: _toggleHaptic,
                  activeTrackColor: WearTheme.jellyfinPurple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerInfo(BuildContext context, EdgeInsets padding, AppState appState) {
    final serverName = appState.currentServer?.name ?? 'Not connected';
    final serverUrl = appState.currentServer?.address ?? '';
    final userName = appState.userName ?? '';

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
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
                const Icon(
                  Icons.dns_outlined,
                  size: 24,
                  color: WearTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  serverName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (serverUrl.isNotEmpty)
                  Text(
                    serverUrl,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (userName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Logged in as $userName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WearTheme.jellyfinPurple,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogout(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
