import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/wear_theme.dart';
import '../../core/utils/watch_shape.dart';
import '../../navigation/app_router.dart';
import '../widgets/common/wear_list_view.dart';

/// Screen requesting notification permission (required on Android 13+).
/// Shown on first launch before navigating to main app flow.
class NotificationPermissionScreen extends StatefulWidget {
  final NotificationPermissionArgs? args;

  const NotificationPermissionScreen({super.key, this.args});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _permissionGranted = false;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _permissionGranted = status.isGranted;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.notification.request();

    if (mounted) {
      setState(() {
        _permissionGranted = status.isGranted;
        _permissionRequested = true;
      });
    }

    // Mark as shown regardless of result
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_permission_shown', true);

    if (mounted && status.isGranted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    final hasAuth = widget.args?.hasAuth ?? false;

    if (hasAuth) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.sessionPicker);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.serverList);
    }
  }

  Future<void> _skipAndContinue() async {
    // Mark as shown
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_permission_shown', true);

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = WatchShape.edgePadding(context);

    return Scaffold(
      backgroundColor: WearTheme.background,
      body: WearListView(
        children: [
          // Page 1: Explanation
          _buildExplanationPage(context, padding),
          // Page 2: Enable button
          _buildEnablePage(context, padding),
          // Page 3: Skip option
          _buildSkipPage(context, padding),
        ],
      ),
    );
  }

  Widget _buildExplanationPage(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 32,
                color: WearTheme.jellyfinPurple,
              ),
              const SizedBox(height: 12),
              Text(
                'Notifications\nRequired',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Shows playback status\non your watch face',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnablePage(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_permissionGranted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: WearTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enabled',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WearTheme.jellyfinPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Enable'),
                ),
              if (_permissionGranted) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateToNextScreen,
                  child: const Text('Continue'),
                ),
              ] else if (_permissionRequested) ...[
                const SizedBox(height: 12),
                Text(
                  'Scroll down to skip',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WearTheme.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipPage(BuildContext context, EdgeInsets padding) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Continue without\nnotifications?',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You can enable later\nin Settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WearTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _skipAndContinue,
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Arguments for the notification permission screen.
class NotificationPermissionArgs {
  /// Whether user has valid auth (determines next screen).
  final bool hasAuth;

  const NotificationPermissionArgs({required this.hasAuth});
}
