import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/wear_theme.dart';
import '../../navigation/app_router.dart';
import '../../state/app_state.dart';
import 'notification_permission_screen.dart';

/// Initial splash screen shown on app launch.
/// Attempts to restore previous session and navigates accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Brief delay to show splash
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Try to restore session from stored credentials
    final appState = context.read<AppState>();
    final success = await appState.tryAutoConnect();

    if (!mounted) return;

    // Check if we need to show notification permission screen
    final shouldShowPermissionScreen = await _shouldShowNotificationPermission();

    if (!mounted) return;

    if (shouldShowPermissionScreen) {
      // Show permission screen first, it will navigate to next screen
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.notificationPermission,
        arguments: NotificationPermissionArgs(hasAuth: success),
      );
    } else if (success) {
      // We have valid auth, go to session picker
      Navigator.of(context).pushReplacementNamed(AppRoutes.sessionPicker);
    } else {
      // No valid auth, go to server list
      Navigator.of(context).pushReplacementNamed(AppRoutes.serverList);
    }
  }

  /// Check if notification permission screen should be shown.
  /// Returns true if Android 13+ and permission hasn't been requested yet.
  Future<bool> _shouldShowNotificationPermission() async {
    // Check if we've already shown the permission screen
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('notification_permission_shown') ?? false;

    if (alreadyShown) {
      return false;
    }

    // Check if permission is already granted
    final status = await Permission.notification.status;
    if (status.isGranted) {
      // Mark as shown since we don't need to ask
      await prefs.setBool('notification_permission_shown', true);
      return false;
    }

    // On Android 13+ (API 33+), we need to request notification permission
    // permission_handler will handle the version check internally
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Jellyfin icon placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: WearTheme.jellyfinPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_circle_filled,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Jellyfin',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
