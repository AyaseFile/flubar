import 'dart:typed_data';

import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/extensions/uint8list_extension.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/models/state/track_cover.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/utils/metadata/updater.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class GroupedTrackCover extends _$GroupedTrackCover with TrackCoverMixin {
  @override
  List<TrackCoverModel> build() {
    final selectedTracks = ref.watch(selectedTracksProvider);
    final coverMap = <Uint8List?, List<Track>>{};

    for (final track in selectedTracks) {
      final cover = track.metadata.picture?.data;
      final existingKey = coverMap.keys.firstWhere(
        (key) => key?.isContentEqual(cover) ?? (cover == null),
        orElse: () => cover,
      );
      coverMap.putIfAbsent(existingKey, () => []).add(track);
    }
    return [
      for (final entry in coverMap.entries)
        TrackCoverModel(oldCover: entry.key, tracks: entry.value),
    ];
  }
}

@riverpod
class BatchedTrackCover extends _$BatchedTrackCover with TrackCoverMixin {
  @override
  List<TrackCoverModel> build() {
    final selectedTracks = ref.watch(selectedTracksProvider);
    return [TrackCoverModel(tracks: selectedTracks)];
  }
}

mixin TrackCoverMixin on AutoDisposeNotifier<List<TrackCoverModel>> {
  void useOldCover() {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.copyWith(updated: false);
      }
      return e;
    }).toList();
  }

  void useNewCover() {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.copyWith(updated: true);
      }
      return e;
    }).toList();
  }

  void removeCover() {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.removeCover();
      }
      return e;
    }).toList();
  }

  void updateCoverState(String mimeType, Uint8List cover) {
    final index = ref.read(currentTrackCoverIndexProvider);
    state = state.map((e) {
      if (e == state[index]) {
        return e.copyWith(updated: true, mimeType: mimeType, newCover: cover);
      }
      return e;
    }).toList();
  }

  Future<void> updateCover() async {
    final id = ref.read(playlistIdProvider).selectedId;
    final updatedTracks = <Track>[];
    var failed = 0;
    await Future.wait(state.map((cover) async {
      if (!cover.updated) return;
      final picture = cover.newCover == null
          ? null
          : Picture(mimeType: cover.mimeType, data: cover.newCover!);
      await Future.wait(cover.tracks.map((t) async {
        final metadata = t.metadata.copyWith(picture: () => picture);
        final tagType =
            await MetadataUpdater.write(metadata: metadata, file: t.path);
        if (tagType == TagType.unknown) {
          failed++;
        } else {
          updatedTracks
              .add(t.copyWith(metadata: metadata.copyWith(tagType: tagType)));
        }
      }));
    }));
    ref.read(playlistsProvider.notifier).updateTracks(id, updatedTracks);
    if (failed != 0) {
      showExceptionSnackbar(title: '错误', message: '无法更新 $failed 个文件的封面');
    }
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
