/// Model representing a discovered or saved Jellyfin server.
class ServerInfo {
  final String id;
  final String name;
  final String address;
  final DateTime? lastConnected;

  const ServerInfo({
    required this.id,
    required this.name,
    required this.address,
    this.lastConnected,
  });

  /// Creates a ServerInfo from UDP discovery JSON response.
  factory ServerInfo.fromDiscoveryJson(Map<String, dynamic> json) {
    return ServerInfo(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? 'Unknown Server',
      address: json['Address'] as String? ?? '',
    );
  }

  /// Creates a ServerInfo from stored JSON.
  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
    );
  }

  /// Converts to JSON for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  /// Creates a copy with updated fields.
  ServerInfo copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? lastConnected,
  }) {
    return ServerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServerInfo(id: $id, name: $name, address: $address)';
}
