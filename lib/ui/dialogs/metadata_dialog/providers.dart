import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/state/common_metadata.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/models.dart';
import 'package:flubar/ui/view/tracklist_view/constants.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'constants.dart';

part 'providers.g.dart';

@riverpod
class SelectedTracks extends _$SelectedTracks {
  @override
  List<Track> build() {
    final selectedIds = ref.watch(selectedTrackIdsProvider);
    final tracks = ref.watch(tracksProvider);
    return tracks.where((track) => selectedIds.contains(track.id)).toList();
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
    }).toList();
    // 不需要手动更新 commonMetadataProvider
  }

  void updateAllMetadataState({
    required int rowId,
    required String? value,
  }) {
    state = state.map((t) {
      final metadata = _updated(t, rowId, value);
      return t.copyWith(metadata: metadata);
    }).toList();
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
      track.metadata.copyWith(trackNumber: () => _parseInt(value)),
  kTrackTitleRowId: (Track track, String? value) =>
      track.metadata.copyWith(title: () => _parseString(value)),
  kArtistNameRowId: (Track track, String? value) =>
      track.metadata.copyWith(artist: () => _parseString(value)),
  kAlbumRowId: (Track track, String? value) =>
      track.metadata.copyWith(album: () => _parseString(value)),
  kAlbumArtistRowId: (Track track, String? value) =>
      track.metadata.copyWith(albumArtist: () => _parseString(value)),
  kTrackTotalRowId: (Track track, String? value) =>
      track.metadata.copyWith(trackTotal: () => _parseInt(value)),
  kDiscNumberRowId: (Track track, String? value) =>
      track.metadata.copyWith(discNumber: () => _parseInt(value)),
  kDiscTotalRowId: (Track track, String? value) =>
      track.metadata.copyWith(discTotal: () => _parseInt(value)),
  kDateRowId: (Track track, String? value) =>
      track.metadata.copyWith(date: () => _parseString(value)),
  kGenreRowId: (Track track, String? value) =>
      track.metadata.copyWith(genre: () => _parseString(value)),
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
  List<CommonMetadataModel> build() {
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

    return [
      CommonMetadataModel(
          id: kTrackTitleRowId,
          key: '标题',
          value: titleSet
              .where((title) => title != null && title.isNotEmpty)
              .join(', '),
          multi: titleSet.length > 1),
      CommonMetadataModel(
          id: kArtistNameRowId,
          key: '艺术家',
          value: artistSet
              .where((artist) => artist != null && artist.isNotEmpty)
              .join(', '),
          multi: artistSet.length > 1),
      CommonMetadataModel(
          id: kAlbumRowId,
          key: '专辑',
          value: albumSet
              .where((album) => album != null && album.isNotEmpty)
              .join(', '),
          multi: albumSet.length > 1),
      CommonMetadataModel(
          id: kAlbumArtistRowId,
          key: '专辑艺术家',
          value: albumArtistSet
              .where((albumArtist) =>
                  albumArtist != null && albumArtist.isNotEmpty)
              .join(', '),
          multi: albumArtistSet.length > 1),
      CommonMetadataModel(
          id: kTrackNumberRowId,
          key: '音轨',
          value: trackNumberSet
              .where((trackNumber) =>
                  trackNumber != null && trackNumber.toString().isNotEmpty)
              .join(', '),
          multi: trackNumberSet.length > 1),
      CommonMetadataModel(
          id: kTrackTotalRowId,
          key: '音轨总数',
          value: trackTotalSet
              .where((trackTotal) =>
                  trackTotal != null && trackTotal.toString().isNotEmpty)
              .join(', '),
          multi: trackTotalSet.length > 1),
      CommonMetadataModel(
          id: kDiscNumberRowId,
          key: '碟片',
          value: discNumberSet
              .where((discNumber) =>
                  discNumber != null && discNumber.toString().isNotEmpty)
              .join(', '),
          multi: discNumberSet.length > 1),
      CommonMetadataModel(
          id: kDiscTotalRowId,
          key: '碟片总数',
          value: discTotalSet
              .where((discTotal) =>
                  discTotal != null && discTotal.toString().isNotEmpty)
              .join(', '),
          multi: discTotalSet.length > 1),
      CommonMetadataModel(
          id: kDateRowId,
          key: '日期',
          value: dateSet
              .where((date) => date != null && date.toString().isNotEmpty)
              .join(', '),
          multi: dateSet.length > 1),
      CommonMetadataModel(
          id: kGenreRowId,
          key: '流派',
          value: genreSet
              .where((genre) => genre != null && genre.isNotEmpty)
              .join(', '),
          multi: genreSet.length > 1),
    ];
  }

  void updateCommonValue(String value) {
    // 批量更新元数据, 适用于选中一行或多行元数据, 并设置为相同的值
    final ids = ref.read(selectedCommonMetadataIdsProvider);
    state = state.map((kv) {
      if (ids.contains(kv.id)) return kv.copyWith(value: value);
      return kv;
    }).toList();
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
    }).toList();
    final selectedTracksNotifier = ref.read(selectedTracksProvider.notifier);
    for (final id in ids) {
      selectedTracksNotifier.updateAllMetadataState(rowId: id, value: null);
    }
  }
}

@riverpod
CommonMetadataModel commonMetadataItem(CommonMetadataItemRef ref) =>
    throw UnimplementedError();

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
  Set<int> build() => {};

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
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
      if (state.length == 1 && state.contains(id)) {
        state = {};
      } else {
        state = {id};
        ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
      }
    } else if (ctrlPressed) {
      toggle(id);
      ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
    } else if (shiftPressed) {
      if (state.isEmpty) {
        state = {id};
        ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
      } else {
        final lastSelectedId = ref.read(lastSelectedCommonMetadataIdProvider);
        final metadataIdsSet =
            ref.read(commonMetadataProvider).map((kv) => kv.id).toSet();
        if (metadataIdsSet.contains(lastSelectedId) &&
            metadataIdsSet.contains(id)) {
          final metadataIds = metadataIdsSet.toList();
          final lastSelectedIndex = metadataIds.indexOf(lastSelectedId);
          final currentIndex = metadataIds.indexOf(id);
          if (currentIndex < lastSelectedIndex) {
            state = {
              for (var i = currentIndex; i <= lastSelectedIndex; i++)
                metadataIds[i]
            };
          } else {
            state = {
              for (var i = lastSelectedIndex; i <= currentIndex; i++)
                metadataIds[i]
            };
          }
        } else {
          state = {id};
          ref.read(lastSelectedCommonMetadataIdProvider.notifier).set(id);
        }
      }
    }
  }
}
