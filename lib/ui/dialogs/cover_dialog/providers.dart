import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/models/extensions/uint8list_extension.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/models/state/track_cover.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class GroupedTrackCover extends _$GroupedTrackCover with TrackCoverMixin {
  @override
  IList<TrackCoverModel> build() {
    final selectedTracks = ref.watch(selectedTracksProvider);
    final coverMap = <Uint8List?, List<Track>>{};
    const listEquality = ListEquality();

    for (final track in selectedTracks) {
      final cover = track.metadata.frontCover;
      final existingKey = coverMap.keys.firstWhere(
        (key) => key?.isContentEqual(listEquality, cover) ?? (cover == null),
        orElse: () => cover,
      );
      coverMap.putIfAbsent(existingKey, () => []).add(track);
    }
    return IList(
      coverMap.entries.map(
        (entry) =>
            TrackCoverModel(oldCover: entry.key, tracks: entry.value.toIList()),
      ),
    );
  }
}

@riverpod
class BatchedTrackCover extends _$BatchedTrackCover with TrackCoverMixin {
  @override
  IList<TrackCoverModel> build() {
    final selectedTracks = ref.watch(selectedTracksProvider);
    return IList([TrackCoverModel(tracks: selectedTracks)]);
  }
}

mixin TrackCoverMixin on $Notifier<IList<TrackCoverModel>> {
  void useOldCover() {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.copyWith(updated: false);
      }
      return e;
    }).toIList();
  }

  void useNewCover() {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.copyWith(updated: true);
      }
      return e;
    }).toIList();
  }

  void removeCover() {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.removeCover();
      }
      return e;
    }).toIList();
  }

  void updateCoverState(Uint8List cover) {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.copyWith(updated: true, newCover: cover);
      }
      return e;
    }).toIList();
  }
}

@riverpod
class CurrentTrackCoverIndex extends _$CurrentTrackCoverIndex {
  @override
  int build() => 0;

  void next() {
    final index = state + 1;
    state = index;
  }

  void previous() {
    final index = state - 1;
    state = index;
  }
}
