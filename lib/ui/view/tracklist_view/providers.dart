import 'package:collection/collection.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/models/state/playlist.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'advanced_column.dart';
import 'constants.dart';

part 'providers.g.dart';

@riverpod
class TrackTableColumns extends _$TrackTableColumns {
  @override
  List<AdvancedColumn> build() {
    return [
      AdvancedColumn(
        id: kTrackNumberColumnId,
        width: kTrackNumberColumnWidth,
      ),
      AdvancedColumn(
        id: kTrackTitleColumnId,
        width: kTrackTitleColumnWidth,
      ),
      AdvancedColumn(
        id: kArtistNameColumnId,
        width: kArtistNameColumnWidth,
      ),
      AdvancedColumn(
        id: kAlbumColumnId,
        width: kAlbumColumnWidth,
      ),
      AdvancedColumn(
        id: kDurationColumnId,
        width: kDurationColumnWidth,
      ),
    ];
  }
}

@Riverpod(keepAlive: true)
class Tracks extends _$Tracks {
  List<Track>? _sortedTracks;
  TrackSortProperty? _lastSortProperty;
  List<Track>? _lastTracks;

  @override
  List<Track> build() {
    final playlist = ref.watch(currentPlaylistProvider);
    final sortProperty = playlist.sortProperty;
    final sortOrder = playlist.sortOrder;
    final tracks = playlist.tracks;

    if (sortProperty == TrackSortProperty.none) {
      _sortedTracks = null;
      _lastSortProperty = null;
      _lastTracks = null;
      return tracks;
    }

    const listEquality = ListEquality();
    if (_sortedTracks == null ||
        _lastSortProperty != sortProperty ||
        !listEquality.equals(_lastTracks, tracks)) {
      _sortedTracks = [...tracks];
      _sortedTracks!
          .sort((a, b) => _compareTracksByProperty(a, b, sortProperty));
      _lastSortProperty = sortProperty;
      _lastTracks = tracks;
    }

    return sortOrder == TrackSortOrder.ascending
        ? _sortedTracks!
        : _sortedTracks!.reversed.toList();
  }

  int _compareTracksByProperty(Track a, Track b, TrackSortProperty property) {
    final aMetadata = a.metadata;
    final bMetadata = b.metadata;

    switch (property) {
      case TrackSortProperty.title:
        return _compareNullableStrings(aMetadata.title, bMetadata.title);
      case TrackSortProperty.artist:
        return _compareNullableStrings(aMetadata.artist, bMetadata.artist);
      case TrackSortProperty.album:
        return _compareNullableStrings(aMetadata.album, bMetadata.album);
      case TrackSortProperty.albumArtist:
        return _compareNullableStrings(
            aMetadata.albumArtist, bMetadata.albumArtist);
      case TrackSortProperty.trackNumber:
        return _compareNullableInts(
            aMetadata.trackNumber, bMetadata.trackNumber);
      case TrackSortProperty.trackTotal:
        return _compareNullableInts(aMetadata.trackTotal, bMetadata.trackTotal);
      case TrackSortProperty.discNumber:
        return _compareNullableInts(aMetadata.discNumber, bMetadata.discNumber);
      case TrackSortProperty.discTotal:
        return _compareNullableInts(aMetadata.discTotal, bMetadata.discTotal);
      case TrackSortProperty.date:
        return _compareNullableStrings(aMetadata.date, bMetadata.date);
      case TrackSortProperty.genre:
        return _compareNullableStrings(aMetadata.genre, bMetadata.genre);
      case TrackSortProperty.duration:
        return _compareNullableDoubles(
            a.properties.duration, b.properties.duration);
      case TrackSortProperty.none:
        return 0;
    }
  }

  int _compareNullableStrings(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return unorm.nfkc(a).compareTo(unorm.nfkc(b));
  }

  int _compareNullableInts(int? a, int? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  int _compareNullableDoubles(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }
}

@riverpod
Track trackItem(Ref ref) => throw UnimplementedError();

@Riverpod(keepAlive: true)
class MaxTrackId extends _$MaxTrackId {
  @override
  int build() => 0;

  int nextId() {
    final id = state + 1;
    state = id;
    return id;
  }
}

@Riverpod(keepAlive: true)
class LastSelectedTrackId extends _$LastSelectedTrackId {
  @override
  int build() => 0;

  void set(int id) {
    state = id;
  }
}

@Riverpod(keepAlive: true)
class SelectedTrackIds extends _$SelectedTrackIds {
  @override
  Set<int> build() => {};

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
    }
  }

  void handleSelectAll() {
    final currentPlayList = ref.read(currentPlaylistProvider);
    final selectedIds = currentPlayList.tracks.map((t) => t.id).toSet();
    if (state.length == selectedIds.length) {
      state = {};
    } else {
      state = selectedIds;
    }
  }

  void clear() {
    state = {};
  }

  void handleSelection(
    int id, {
    required bool ctrlPressed,
    required bool shiftPressed,
  }) {
    if (!ctrlPressed && !shiftPressed) {
      // 单选情况
      if (state.length == 1 && state.contains(id)) {
        // 取消选中
        state = {};
      } else {
        state = {id};
        ref.read(lastSelectedTrackIdProvider.notifier).set(id);
      }
    } else if (ctrlPressed) {
      // 加入集合中
      toggle(id);
      ref.read(lastSelectedTrackIdProvider.notifier).set(id);
    } else if (shiftPressed) {
      if (state.isEmpty) {
        state = {id};
        ref.read(lastSelectedTrackIdProvider.notifier).set(id);
      } else {
        // 范围选择
        final lastSelectedId = ref.read(lastSelectedTrackIdProvider);
        final trackIdsSet = ref.read(tracksProvider).map((t) => t.id).toSet();
        if (trackIdsSet.contains(lastSelectedId) && trackIdsSet.contains(id)) {
          final trackIds = trackIdsSet.toList();
          final lastSelectedIndex = trackIds.indexOf(lastSelectedId);
          final currentIndex = trackIds.indexOf(id);
          if (currentIndex < lastSelectedIndex) {
            state = {
              for (var i = currentIndex; i <= lastSelectedIndex; i++)
                trackIds[i]
            };
          } else {
            state = {
              for (var i = lastSelectedIndex; i <= currentIndex; i++)
                trackIds[i]
            };
          }
        } else {
          state = {id};
          ref.read(lastSelectedTrackIdProvider.notifier).set(id);
        }
      }
    }
  }
}
