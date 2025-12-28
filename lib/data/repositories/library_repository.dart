import 'package:flutter/foundation.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

import '../../core/constants/jellyfin_constants.dart';
import '../jellyfin/jellyfin_client_wrapper.dart';
import '../models/library_item.dart';

/// Repository for browsing Jellyfin libraries.
class LibraryRepository {
  final JellyfinClientWrapper _client;

  LibraryRepository(this._client);

  /// Gets the user's library views (Movies, TV Shows, Music, etc.).
  Future<List<LibraryView>> getLibraries() async {
    final userId = _client.userId;
    debugPrint('[LibraryRepo] getLibraries - userId: $userId, isAuth: ${_client.isAuthenticated}');

    if (userId == null) {
      debugPrint('[LibraryRepo] userId is null');
      return [];
    }

    try {
      // Use UserViewsApi to get user's library views
      final response = await _client.client?.getUserViewsApi().getUserViews(userId: userId);
      debugPrint('[LibraryRepo] Response: ${response?.statusCode}, items: ${response?.data?.items?.length}');

      final items = response?.data?.items ?? [];
      return items.map((dto) {
        debugPrint('[LibraryRepo] Processing: ${dto.name}, collectionType: ${dto.collectionType}');
        return LibraryView.fromDto(dto);
      }).toList();
    } catch (e, stack) {
      debugPrint('[LibraryRepo] Error: $e\n$stack');
      return [];
    }
  }

  /// Gets items from a library or folder.
  Future<List<LibraryItem>> getItems({
    required String parentId,
    List<BaseItemKind>? includeItemTypes,
    int startIndex = 0,
    int limit = JellyfinConstants.defaultPageSize,
    ItemSortBy? sortBy,
    SortOrder? sortOrder,
  }) async {
    final userId = _client.userId;
    if (userId == null) return [];

    try {
      final response = await _client.itemsApi?.getItems(
        userId: userId,
        parentId: parentId,
        includeItemTypes: includeItemTypes,
        startIndex: startIndex,
        limit: limit,
        sortBy: [sortBy ?? ItemSortBy.sortName],
        sortOrder: [sortOrder ?? SortOrder.ascending],
        fields: [
          ItemFields.overview,
          ItemFields.primaryImageAspectRatio,
        ],
        imageTypeLimit: 1,
        enableImageTypes: [ImageType.primary, ImageType.backdrop],
      );

      final items = response?.data?.items ?? [];
      return items.map((dto) => LibraryItem.fromDto(dto)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets seasons for a TV series.
  Future<List<LibraryItem>> getSeasons(String seriesId) async {
    final userId = _client.userId;
    if (userId == null) return [];

    try {
      final response = await _client.client?.getTvShowsApi().getSeasons(
        seriesId: seriesId,
        userId: userId,
      );

      final items = response?.data?.items ?? [];
      return items.map((dto) => LibraryItem.fromDto(dto)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets episodes for a TV series season.
  Future<List<LibraryItem>> getEpisodes({
    required String seriesId,
    String? seasonId,
    int? seasonNumber,
  }) async {
    final userId = _client.userId;
    if (userId == null) return [];

    try {
      final response = await _client.client?.getTvShowsApi().getEpisodes(
        seriesId: seriesId,
        userId: userId,
        seasonId: seasonId,
        season: seasonNumber,
        fields: [ItemFields.overview],
      );

      final items = response?.data?.items ?? [];
      return items.map((dto) => LibraryItem.fromDto(dto)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets tracks for a music album.
  Future<List<LibraryItem>> getAlbumTracks(String albumId) async {
    return getItems(
      parentId: albumId,
      includeItemTypes: [BaseItemKind.audio],
      sortBy: ItemSortBy.indexNumber,
    );
  }

  /// Gets albums for an artist.
  Future<List<LibraryItem>> getArtistAlbums(String artistId) async {
    final userId = _client.userId;
    if (userId == null) return [];

    try {
      final response = await _client.itemsApi?.getItems(
        userId: userId,
        albumArtistIds: [artistId],
        includeItemTypes: [BaseItemKind.musicAlbum],
        sortBy: [ItemSortBy.productionYear, ItemSortBy.sortName],
        sortOrder: [SortOrder.descending, SortOrder.ascending],
      );

      final items = response?.data?.items ?? [];
      return items.map((dto) => LibraryItem.fromDto(dto)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets a single item by ID.
  Future<LibraryItem?> getItem(String itemId) async {
    final userId = _client.userId;
    if (userId == null) return null;

    try {
      final response = await _client.userLibraryApi?.getItem(
        userId: userId,
        itemId: itemId,
      );

      if (response?.data != null) {
        return LibraryItem.fromDto(response!.data!);
      }
    } catch (e) {
      // Item not found
    }

    return null;
  }

  /// Searches for items by name.
  Future<List<LibraryItem>> search({
    required String query,
    List<BaseItemKind>? includeItemTypes,
    int limit = 20,
  }) async {
    final userId = _client.userId;
    if (userId == null) return [];

    try {
      final response = await _client.itemsApi?.getItems(
        userId: userId,
        searchTerm: query,
        includeItemTypes: includeItemTypes,
        limit: limit,
        recursive: true,
      );

      final items = response?.data?.items ?? [];
      return items.map((dto) => LibraryItem.fromDto(dto)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets the image URL for an item.
  String? getImageUrl(
    String itemId, {
    ImageType imageType = ImageType.primary,
    int maxWidth = JellyfinConstants.imageMaxWidth,
  }) {
    return _client.getImageUrl(
      itemId,
      imageType: imageType,
      maxWidth: maxWidth,
    );
  }
}
