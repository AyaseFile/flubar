import 'dart:math' show max, min;

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/state/common_metadata.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/models.dart';
import 'package:flubar/ui/view/tracklist_view/constants.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'constants.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
class SelectedTracks extends _$SelectedTracks {
  @override
  IList<Track> build() {
    final selectedIds = ref.watch(selectedTrackIdsProvider);
    final tracks = ref.watch(tracksProvider);
    return tracks.where((track) => selectedIds.contains(track.id)).toIList();
  }

  void updateMetadataState({
    required int trackId,
    required int columnId,
    required String value,
  }) {
    // 仅更新此 provider 中的元数据, 不负责更新 tracksProvider 和写入文件
    final track = state.firstWhere((track) => track.id == trackId);
    final rowId = switch (columnId) {
      kTrackNumberColumnId => kTrackNumberRowId,
      kTrackTitleColumnId => kTrackTitleRowId,
      kArtistNameColumnId => kArtistNameRowId,
      kAlbumColumnId => kAlbumRowId,
      kAlbumArtistColumnId => kAlbumArtistRowId,
      kTrackTotalColumnId => kTrackTotalRowId,
      kDiscNumberColumnId => kDiscNumberRowId,
      kDiscTotalColumnId => kDiscTotalRowId,
      kDateColumnId => kDateRowId,
      kGenreColumnId => kGenreRowId,
      _ => throw UnimplementedError(),
    };
    final metadata = _updated(track, rowId, value);
    state = state.map((t) {
      if (t.id == trackId) return t.copyWith(metadata: metadata);
      return t;
    }).toIList();
    // 不需要手动更新 commonMetadataProvider
  }

  void updateAllMetadataState({required int rowId, required String? value}) {
    state = state.map((t) {
      final metadata = _updated(t, rowId, value);
      return t.copyWith(metadata: metadata);
    }).toIList();
  }

  Metadata _updated(Track track, int rowId, String? value) {
    final updateFunction = _updateFunctions[rowId];
    if (updateFunction != null) {
      return updateFunction(track, value);
    } else {
      throw UnimplementedError();
    }
  }
}

final _updateFunctions = {
  kTrackNumberRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(trackNumber: () => _parseInt(value)),
  kTrackTitleRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(title: () => _parseString(value)),
  kArtistNameRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(artist: () => _parseString(value)),
  kAlbumRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(album: () => _parseString(value)),
  kAlbumArtistRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(albumArtist: () => _parseString(value)),
  kTrackTotalRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(trackTotal: () => _parseInt(value)),
  kDiscNumberRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(discNumber: () => _parseInt(value)),
  kDiscTotalRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(discTotal: () => _parseInt(value)),
  kDateRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(date: () => _parseString(value)),
  kGenreRowId: (Track track, String? value) =>
      track.metadata.nullableCopyWith(genre: () => _parseString(value)),
};

String? _parseString(String? value) {
  return value == null || value.isEmpty ? null : value;
}

int? _parseInt(String? value) {
  return value == null || value.isEmpty ? null : int.tryParse(value);
}

@riverpod
class CommonMetadata extends _$CommonMetadata {
  @override
  IList<CommonMetadataModel> build() {
    final selectedTracks = ref.watch(selectedTracksProvider);
    final metadata = selectedTracks.map((track) => track.metadata);
    final titleSet = <String?>{};
    final artistSet = <String?>{};
    final albumSet = <String?>{};
    final albumArtistSet = <String?>{};
    final trackNumberSet = <int?>{};
    final trackTotalSet = <int?>{};
    final discNumberSet = <int?>{};
    final discTotalSet = <int?>{};
    final dateSet = <String?>{};
    final genreSet = <String?>{};

    for (final m in metadata) {
      titleSet.add(m.title);
      artistSet.add(m.artist);
      albumSet.add(m.album);
      albumArtistSet.add(m.albumArtist);
      trackNumberSet.add(m.trackNumber);
      trackTotalSet.add(m.trackTotal);
      discNumberSet.add(m.discNumber);
      discTotalSet.add(m.discTotal);
      dateSet.add(m.date);
      genreSet.add(m.genre);
    }

    return IList([
      CommonMetadataModel(
        id: kTrackTitleRowId,
        key: '标题',
        value: _formatValues(titleSet),
        multi: titleSet.length > 1,
      ),
      CommonMetadataModel(
        id: kArtistNameRowId,
        key: '艺术家',
        value: _formatValues(artistSet),
        multi: artistSet.length > 1,
      ),
      CommonMetadataModel(
        id: kAlbumRowId,
        key: '专辑',
        value: _formatValues(albumSet),
        multi: albumSet.length > 1,
      ),
      CommonMetadataModel(
        id: kAlbumArtistRowId,
        key: '专辑艺术家',
        value: _formatValues(albumArtistSet),
        multi: albumArtistSet.length > 1,
      ),
      CommonMetadataModel(
        id: kTrackNumberRowId,
        key: '音轨',
        value: _formatValues(trackNumberSet),
        multi: trackNumberSet.length > 1,
      ),
      CommonMetadataModel(
        id: kTrackTotalRowId,
        key: '音轨总数',
        value: _formatValues(trackTotalSet),
        multi: trackTotalSet.length > 1,
      ),
      CommonMetadataModel(
        id: kDiscNumberRowId,
        key: '碟片',
        value: _formatValues(discNumberSet),
        multi: discNumberSet.length > 1,
      ),
      CommonMetadataModel(
        id: kDiscTotalRowId,
        key: '碟片总数',
        value: _formatValues(discTotalSet),
        multi: discTotalSet.length > 1,
      ),
      CommonMetadataModel(
        id: kDateRowId,
        key: '日期',
        value: _formatValues(dateSet),
        multi: dateSet.length > 1,
      ),
      CommonMetadataModel(
        id: kGenreRowId,
        key: '流派',
        value: _formatValues(genreSet),
        multi: genreSet.length > 1,
      ),
    ]);
  }

  String _formatValues<T>(Set<T?> values) {
    if (values.isEmpty) return '';

    final nonNullValues = values.where(
      (v) => v != null && v.toString().isNotEmpty,
    );

    final parts = <String>[];
    if (nonNullValues.isNotEmpty) {
      parts.add(nonNullValues.join(', '));
    }

    return parts.join(', ');
  }

  void updateCommonValue(String value) {
    // 批量更新元数据, 适用于选中一行或多行元数据, 并设置为相同的值
    final ids = ref.read(selectedCommonMetadataIdsProvider);
    state = state.map((kv) {
      if (ids.contains(kv.id)) return kv.copyWith(value: value);
      return kv;
    }).toIList();
    // 手动更新 selectedTracksProvider 中的元数据
    final selectedTracksNotifier = ref.read(selectedTracksProvider.notifier);
    for (final id in ids) {
      selectedTracksNotifier.updateAllMetadataState(rowId: id, value: value);
    }
  }

  void removeCommonValue() {
    // 同理
    final ids = ref.read(selectedCommonMetadataIdsProvider);
    state = state.map((kv) {
      if (ids.contains(kv.id)) return kv.copyWith(value: '');
      return kv;
    }).toIList();
    final selectedTracksNotifier = ref.read(selectedTracksProvider.notifier);
    for (final id in ids) {
      selectedTracksNotifier.updateAllMetadataState(rowId: id, value: null);
    }
  }
}

@riverpod
CommonMetadataModel commonMetadataItem(Ref ref) => throw UnimplementedError();

@riverpod
class LastSelectedCommonMetadataId extends _$LastSelectedCommonMetadataId {
  @override
  int build() => 0;

  void set(int id) {
    state = id;
  }
}

@riverpod
class SelectedCommonMetadataIds extends _$SelectedCommonMetadataIds {
  @override
  ISet<int> build() => const ISet.empty();

  void toggle(int id) {
    if (state.contains(id)) {
      state = state.remove(id);
    } else {
      state = state.add(id);
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
      if (state.length == 1 && state.contains(id)) {
        state = const ISet.empty();
      } else {
        state = ISet({id});
        ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
      }
    } else if (ctrlPressed || metaPressed) {
      toggle(id);
      ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
    } else if (shiftPressed) {
      if (state.isEmpty) {
        state = ISet({id});
        ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
      } else {
        final lastSelectedId = ref.read(lastSelectedCommonMetadataIdProvider);
        final metadataIds = ref
            .read(commonMetadataProvider)
            .map((kv) => kv.id)
            .toIList();
        final lastSelectedIndex = metadataIds.indexOf(lastSelectedId);
        final currentIndex = metadataIds.indexOf(id);
        if (lastSelectedIndex != -1 && currentIndex != -1) {
          final start = min(currentIndex, lastSelectedIndex);
          final end = max(currentIndex, lastSelectedIndex);
          state = metadataIds.sublist(start, end + 1).toISet();
        } else {
          state = ISet({id});
          ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
        }
      }
    }
  }
}
