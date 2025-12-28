import 'package:flutter/material.dart';

/// Model representing an active Jellyfin session/device.
class SessionDevice {
  final String sessionId;
  final String deviceName;
  final String deviceId;
  final String client;
  final String? userName;
  final bool supportsRemoteControl;
  final bool supportsMediaControl;
  final String? nowPlayingItemId;
  final String? nowPlayingItemName;
  final String? nowPlayingItemType;

  const SessionDevice({
    required this.sessionId,
    required this.deviceName,
    required this.deviceId,
    required this.client,
    this.userName,
    this.supportsRemoteControl = false,
    this.supportsMediaControl = false,
    this.nowPlayingItemId,
    this.nowPlayingItemName,
    this.nowPlayingItemType,
  });

  /// Returns an appropriate icon for the client type.
  IconData get icon {
    final clientLower = client.toLowerCase();

    if (clientLower.contains('android') || clientLower.contains('mobile')) {
      return Icons.phone_android;
    }
    if (clientLower.contains('ios') || clientLower.contains('iphone') || clientLower.contains('ipad')) {
      return Icons.phone_iphone;
    }
    if (clientLower.contains('tv') || clientLower.contains('roku') || clientLower.contains('fire')) {
      return Icons.tv;
    }
    if (clientLower.contains('web') || clientLower.contains('browser')) {
      return Icons.language;
    }
    if (clientLower.contains('kodi') || clientLower.contains('infuse')) {
      return Icons.connected_tv;
    }
    if (clientLower.contains('chromecast') || clientLower.contains('cast')) {
      return Icons.cast;
    }
    if (clientLower.contains('windows') || clientLower.contains('mac') || clientLower.contains('desktop')) {
      return Icons.computer;
    }

    return Icons.devices;
  }

  /// Whether this session is currently playing something.
  bool get isPlaying => nowPlayingItemId != null;

  /// Creates a SessionDevice from a Jellyfin SessionInfoDto.
  factory SessionDevice.fromDto(dynamic dto) {
    final playState = dto.playState;
    final nowPlaying = dto.nowPlayingItem;

    return SessionDevice(
      sessionId: dto.id ?? '',
      deviceName: dto.deviceName ?? 'Unknown Device',
      deviceId: dto.deviceId ?? '',
      client: dto.client ?? 'Unknown Client',
      userName: dto.userName,
      supportsRemoteControl: dto.supportsRemoteControl ?? false,
      supportsMediaControl: dto.supportsMediaControl ?? false,
      nowPlayingItemId: nowPlaying?.id,
      nowPlayingItemName: nowPlaying?.name,
      nowPlayingItemType: nowPlaying?.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionDevice && other.sessionId == sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;

  @override
  String toString() => 'SessionDevice(id: $sessionId, device: $deviceName, client: $client)';
}
