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
  List<Playlist> build() => const <Playlist>[
        Playlist(id: kDefaultPlaylistId, name: kDefaultPlaylistName, tracks: [])
      ];

  void addPlaylists(Iterable<Playlist> playlists) {
    state = [...state, ...playlists];
  }

  void removePlaylist(int id) {
    final selected = ref.read(playlistIdProvider).selectedId == id;
    if (!selected) {
      state = state.where((playlist) => playlist.id != id).toList();
      return;
    }
    // 如果删除的是当前选中的播放列表，则选中上一个播放列表 (能保证存在上一个播放列表, 因为默认播放列表不可删除)
    int? previousId;
    state = state.where((playlist) {
      if (playlist.id == id) {
        ref
            .read(playlistIdProvider.notifier)
            .select(previousId ?? kDefaultPlaylistId);
        return false;
      } else {
        previousId = playlist.id;
        return true;
      }
    }).toList();
  }

  void updatePlaylist(Playlist playlist) {
    state = state.map((p) => p.id == playlist.id ? playlist : p).toList();
  }

  void addTracks(int id, Iterable<Track> tracks) {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(tracks: [...p.tracks, ...tracks]);
      }
      return p;
    }).toList();
  }

  void removeTracks() {
    final id = ref.read(playlistIdProvider).selectedId;
    final trackIds = ref.read(selectedTrackIdsProvider);
    state = state.map((playlist) {
      if (playlist.id == id) {
        final newTracks = playlist.tracks
            .where((track) => !trackIds.contains(track.id))
            .toList();
        final hasChanges = newTracks.length != playlist.tracks.length;
        return hasChanges ? playlist.copyWith(tracks: newTracks) : playlist;
      }
      return playlist;
    }).toList();
    ref.read(selectedTrackIdsProvider.notifier).clear();
  }

  void updateTrack(int id, Track track) {
    state = state.map((p) {
      if (p.id == id) {
        final newTracks =
            p.tracks.map((t) => t.id == track.id ? track : t).toList();
        return p.copyWith(tracks: newTracks);
      }
      return p;
    }).toList();
  }

  void updateTracks(int id, Iterable<Track> tracks) {
    final updateMap = {for (final track in tracks) track.id: track};
    state = state.map((p) {
      if (p.id == id) {
        final newTracks =
            p.tracks.map((track) => updateMap[track.id] ?? track).toList();
        final hasChanged =
            p.tracks.any((track) => updateMap.containsKey(track.id));
        return hasChanged ? p.copyWith(tracks: newTracks) : p;
      }
      return p;
    }).toList();
  }

  void reorderTracks(int id, int oldIndex, int newIndex) {
    state = state.map((p) {
      if (p.id == id) {
        final tracks = [...p.tracks];
        final track = tracks.removeAt(oldIndex);
        tracks.insert(newIndex, track);
        return p.copyWith(tracks: tracks);
      }
      return p;
    }).toList();
  }
}

@Riverpod(keepAlive: true)
class CurrentPlaylist extends _$CurrentPlaylist {
  @override
  Playlist build() {
    final id = ref.watch(playlistIdProvider).selectedId;
    return ref.watch(playlistsProvider.select((playlists) =>
        playlists.firstWhere((p) => p.id == id,
            orElse: () => throw StateError('No playlist found with id $id'))));
  }

  void setSortProperty(TrackSortProperty property) {
    _updatePlaylist(state.copyWith(sortProperty: property));
  }

  void setSortOrder(TrackSortOrder order) {
    _updatePlaylist(state.copyWith(sortOrder: order));
  }

  void resetSortPropertyAndOrder() {
    _updatePlaylist(state.copyWith(
        sortProperty: TrackSortProperty.none,
        sortOrder: TrackSortOrder.ascending));
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
