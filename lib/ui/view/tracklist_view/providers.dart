import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/models/state/playlist.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'advanced_column.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
class TrackTableColumns extends _$TrackTableColumns {
  @override
  List<AdvancedColumn> build() {
    return ref
        .read(tableColumnStateProvider)
        .trackTableColumns
        .map((state) => AdvancedColumn.fromState(state))
        .toList();
  }

  void translateColumn(int index, double translation) {
    state[index] = state[index].copyWith(translation: translation);
  }

  void resizeColumn(int index, double width) {
    state[index] = state[index].copyWith(width: width);
  }

  void moveColumn(int oldIndex, int newIndex) {
    final column = state.removeAt(oldIndex);
    state.insert(newIndex, column);
  }
}

@Riverpod(keepAlive: true)
class Tracks extends _$Tracks {
  @override
  IList<Track> build() {
    final playlist = ref.watch(currentPlaylistProvider);
    final sortProperty = playlist.sortProperty;
    final sortOrder = playlist.sortOrder;
    final tracks = playlist.tracks;

    if (sortProperty == TrackSortProperty.none) {
      return tracks;
    }

    final sortedTracks =
        tracks.sorted((a, b) => _compareTracksByProperty(a, b, sortProperty));
    return sortOrder == TrackSortOrder.ascending
        ? sortedTracks.toIList()
        : sortedTracks.reversed.toIList();
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
  ISet<int> build() => const ISet.empty();

  void toggle(int id) {
    if (state.contains(id)) {
      state = state.remove(id);
    } else {
      state = state.add(id);
    }
  }

  void handleSelectAll() {
    final currentPlayList = ref.read(currentPlaylistProvider);
    final selectedIds = currentPlayList.tracks.map((t) => t.id).toISet();
    if (state.length == selectedIds.length) {
      state = const ISet.empty();
    } else {
      state = selectedIds;
    }
  }

  void clear() {
    state = const ISet.empty();
  }

  void handleSelection(
    int id, {
    required bool ctrlPressed,
    required bool metaPressed,
    required bool shiftPressed,
  }) {
    if (!ctrlPressed && !metaPressed && !shiftPressed) {
      // 单选情况
      if (state.length == 1 && state.contains(id)) {
        // 取消选中
        state = const ISet.empty();
      } else {
        state = ISet({id});
        ref.read(lastSelectedTrackIdProvider.notifier).set(id);
      }
    } else if (ctrlPressed || metaPressed) {
      // 加入集合中
      toggle(id);
      ref.read(lastSelectedTrackIdProvider.notifier).set(id);
    } else if (shiftPressed) {
      if (state.isEmpty) {
        state = ISet({id});
        ref.read(lastSelectedTrackIdProvider.notifier).set(id);
      } else {
        // 范围选择
        final lastSelectedId = ref.read(lastSelectedTrackIdProvider);
        final trackIds = ref.read(tracksProvider).map((t) => t.id).toIList();
        final lastSelectedIndex = trackIds.indexOf(lastSelectedId);
        final currentIndex = trackIds.indexOf(id);
        if (lastSelectedIndex != -1 && currentIndex != -1) {
          final start = min(currentIndex, lastSelectedIndex);
          final end = max(currentIndex, lastSelectedIndex);
          state = trackIds.sublist(start, end + 1).toISet();
        } else {
          state = ISet({id});
          ref.read(lastSelectedTrackIdProvider.notifier).set(id);
        }
      }
    }
  }
}
