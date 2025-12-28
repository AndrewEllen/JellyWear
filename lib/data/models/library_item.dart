import 'package:jellyfin_dart/jellyfin_dart.dart';

import '../../core/constants/jellyfin_constants.dart';

/// Model representing a library item (movie, episode, song, etc.).
class LibraryItem {
  final String id;
  final String name;
  final String type;
  final String? seriesId;
  final String? seriesName;
  final String? albumId;
  final String? albumName;
  final String? artistName;
  final int? indexNumber;
  final int? parentIndexNumber;
  final int? runTimeTicks;
  final String? overview;
  final int? productionYear;
  final String? imagePrimaryTag;
  final String? imageBackdropTag;
  final double? communityRating;

  const LibraryItem({
    required this.id,
    required this.name,
    required this.type,
    this.seriesId,
    this.seriesName,
    this.albumId,
    this.albumName,
    this.artistName,
    this.indexNumber,
    this.parentIndexNumber,
    this.runTimeTicks,
    this.overview,
    this.productionYear,
    this.imagePrimaryTag,
    this.imageBackdropTag,
    this.communityRating,
  });

  /// Whether this item can be played directly.
  bool get isPlayable {
    return type == 'Movie' ||
        type == 'Episode' ||
        type == 'Audio' ||
        type == 'MusicVideo' ||
        type == 'Trailer';
  }

  /// Whether this item is a folder/container.
  bool get isFolder {
    return type == 'Series' ||
        type == 'Season' ||
        type == 'MusicAlbum' ||
        type == 'MusicArtist' ||
        type == 'Folder' ||
        type == 'CollectionFolder' ||
        type == 'Playlist' ||
        type == 'BoxSet';
  }

  /// Returns a formatted runtime string (e.g., "1h 30m").
  String? get formattedRuntime {
    if (runTimeTicks == null) return null;

    final totalSeconds = runTimeTicks! ~/ JellyfinConstants.ticksPerSecond;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Returns a subtitle string based on item type.
  String? get subtitle {
    switch (type) {
      case 'Episode':
        if (seriesName != null && indexNumber != null) {
          final seasonEp = parentIndexNumber != null
              ? 'S${parentIndexNumber}E$indexNumber'
              : 'E$indexNumber';
          return '$seriesName • $seasonEp';
        }
        return seriesName;
      case 'Audio':
        return artistName ?? albumName;
      case 'Season':
        return seriesName;
      case 'MusicAlbum':
        return artistName;
      default:
        if (productionYear != null) {
          return productionYear.toString();
        }
        return null;
    }
  }

  /// Creates a LibraryItem from a Jellyfin BaseItemDto.
  factory LibraryItem.fromDto(BaseItemDto dto) {
    return LibraryItem(
      id: dto.id ?? '',
      name: dto.name ?? 'Unknown',
      type: dto.type?.value ?? '',
      seriesId: dto.seriesId,
      seriesName: dto.seriesName,
      albumId: dto.albumId,
      artistName: dto.albumArtist ?? (dto.artists?.isNotEmpty == true ? dto.artists!.first : null),
      indexNumber: dto.indexNumber,
      parentIndexNumber: dto.parentIndexNumber,
      runTimeTicks: dto.runTimeTicks,
      overview: dto.overview,
      productionYear: dto.productionYear,
      imagePrimaryTag: dto.imageTags?['Primary'],
      imageBackdropTag: dto.backdropImageTags?.isNotEmpty == true
          ? dto.backdropImageTags!.first
          : null,
      communityRating: dto.communityRating,
    );
  }

  @override
  String toString() => 'LibraryItem(id: $id, name: $name, type: $type)';
}

/// Represents a user's library view (Movies, TV Shows, Music, etc.).
class LibraryView {
  final String id;
  final String name;
  final String? collectionType;

  const LibraryView({
    required this.id,
    required this.name,
    this.collectionType,
  });

  /// Creates a LibraryView from a Jellyfin BaseItemDto.
  factory LibraryView.fromDto(BaseItemDto dto) {
    return LibraryView(
      id: dto.id ?? '',
      name: dto.name ?? 'Unknown',
      collectionType: dto.collectionType?.value,
    );
  }

  @override
  String toString() => 'LibraryView(id: $id, name: $name, type: $collectionType)';
}
