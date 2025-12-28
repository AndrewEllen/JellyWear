import 'package:flutter/services.dart';

/// Service to manage the Wear OS Ongoing Activity.
///
/// This keeps the app visible in the Recents section and prevents
/// the system from dismissing it after the screen timeout.
class OngoingActivityService {
  static const _channel = MethodChannel('com.jellywear.jellyfin_wear_os/ongoing_activity');

  /// Starts the ongoing activity with an optional title.
  static Future<void> start({String title = 'Jellyfin Remote'}) async {
    try {
      await _channel.invokeMethod('startOngoingActivity', {'title': title});
    } on PlatformException catch (_) {
      // Silently fail on non-Wear OS devices or if service fails to start
    }
  }

  /// Stops the ongoing activity.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopOngoingActivity');
    } on PlatformException catch (_) {
      // Silently fail
    }
  }
}
