import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  @override
  List<Track> build() {
    final playlist = ref.watch(currentPlaylistProvider);
    return playlist.tracks;
  }
}

@riverpod
Track trackItem(TrackItemRef ref) => throw UnimplementedError();

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
