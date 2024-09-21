import 'package:flubar/ui/view/playlist_view/constants.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'track.dart';

part 'playlist.freezed.dart';

enum TrackSortProperty {
  title,
  artist,
  album,
  albumArtist,
  trackNumber,
  trackTotal,
  discNumber,
  discTotal,
  date,
  genre,
  duration,
  none,
}

enum TrackSortOrder {
  ascending,
  descending,
}

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required int id,
    required String name,
    required List<Track> tracks,
    @Default(TrackSortProperty.none) TrackSortProperty sortProperty,
    @Default(TrackSortOrder.ascending) TrackSortOrder sortOrder,
  }) = _Playlist;
}

@freezed
class PlaylistIdState with _$PlaylistIdState {
  const factory PlaylistIdState({
    @Default(kDefaultPlaylistId) int selectedId,
    @Default(kDefaultPlaylistId) int maxId,
  }) = _PlaylistIdState;
}
