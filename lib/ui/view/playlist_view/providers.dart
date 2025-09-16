import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/models/state/playlist.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'constants.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
class Playlists extends _$Playlists {
  @override
  IList<Playlist> build() => IList([
    Playlist(
      id: kDefaultPlaylistId,
      name: kDefaultPlaylistName,
      tracks: const IList.empty(),
    ),
  ]);

  void addPlaylists(Iterable<Playlist> playlists) {
    state = state.addAll(playlists);
  }

  void removePlaylist(Playlist playlist) {
    final selected = ref.read(playlistIdProvider).selectedId == playlist.id;
    if (!selected) {
      state = state.remove(playlist);
      return;
    }
    // 如果删除的是当前选中的播放列表, 则选中上一个播放列表 (能保证存在上一个播放列表, 因为默认播放列表不可删除)
    final index = state.indexOf(playlist);
    final prevIndex = index == 0 ? 0 : index - 1;
    final prevPlaylist = state[prevIndex];
    ref.read(playlistIdProvider.notifier).select(prevPlaylist.id);
    state = state.remove(playlist);
  }

  void updatePlaylist(Playlist playlist) {
    state = state.map((p) => p.id == playlist.id ? playlist : p).toIList();
  }

  void addTracks(int id, Iterable<Track> tracks) {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(tracks: p.tracks.addAll(tracks));
      }
      return p;
    }).toIList();
  }

  void removeTracks() {
    final id = ref.read(playlistIdProvider).selectedId;
    final trackIds = ref.read(selectedTrackIdsProvider);
    ref.read(selectedTrackIdsProvider.notifier).clear();
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(
          tracks: p.tracks.removeWhere((t) => trackIds.contains(t.id)),
        );
      }
      return p;
    }).toIList();
  }

  void updateTracks(int id, Iterable<Track> tracks) {
    final updateMap = {for (final track in tracks) track.id: track};
    state = state.map((p) {
      if (p.id == id) {
        final updatedTracks = p.tracks
            .map((t) => updateMap[t.id] ?? t)
            .toIList();
        return p.copyWith(tracks: updatedTracks);
      }
      return p;
    }).toIList();
  }

  void reorderTracks(int id, int oldIndex, int newIndex) {
    state = state.map((p) {
      if (p.id == id) {
        final tracks = p.tracks;
        final track = tracks[oldIndex];
        final newTracks = tracks.removeAt(oldIndex).insert(newIndex, track);
        return p.copyWith(tracks: newTracks);
      }
      return p;
    }).toIList();
  }
}

@Riverpod(keepAlive: true)
class CurrentPlaylist extends _$CurrentPlaylist {
  @override
  Playlist build() {
    final id = ref.watch(
      playlistIdProvider.select((state) => state.selectedId),
    );
    return ref.watch(
      playlistsProvider.select(
        (state) => state.firstWhere(
          (p) => p.id == id,
          orElse: () => throw StateError('No playlist found with id $id'),
        ),
      ),
    );
  }

  void setSortProperty(TrackSortProperty property) {
    _updatePlaylist(state.copyWith(sortProperty: property));
  }

  void setSortOrder(TrackSortOrder order) {
    _updatePlaylist(state.copyWith(sortOrder: order));
  }

  void resetSortPropertyAndOrder() {
    _updatePlaylist(
      state.copyWith(
        sortProperty: TrackSortProperty.none,
        sortOrder: TrackSortOrder.ascending,
      ),
    );
  }

  void _updatePlaylist(Playlist playlist) {
    ref.read(playlistsProvider.notifier).updatePlaylist(playlist);
  }
}

@riverpod
Playlist playlistItem(Ref ref) => throw UnimplementedError();

@Riverpod(keepAlive: true)
class PlaylistId extends _$PlaylistId {
  @override
  PlaylistIdState build() => const PlaylistIdState();

  void select(int id) {
    state = state.copyWith(selectedId: id);
  }

  int nextId() {
    final id = state.maxId + 1;
    state = state.copyWith(maxId: id);
    return id;
  }
}
