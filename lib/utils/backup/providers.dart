import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/state/metadata_backup.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/models.dart';
import 'package:flubar/ui/dialogs/metadata_backup_dialog/providers.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/utils/backup/constants.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class MetadataExportUtil extends _$MetadataExportUtil {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> export() async {
    state = const AsyncValue.loading();

    try {
      final path = ref.read(pathProvider);
      final selectedTracks = ref.read(selectedTracksProvider);
      await _export(path!, selectedTracks);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _export(String path, IList<Track> tracks) async {
    try {
      final uniqueFrontCovers = <Uint8List>[];
      final listEquality = const ListEquality<int>();
      final coverMap = LinkedHashMap<Uint8List, int>(
        equals: listEquality.equals,
        hashCode: listEquality.hash,
      );

      final metadataList = tracks.map((track) {
        int? frontCoverIndex;
        final frontCover = track.metadata.frontCover;
        if (frontCover != null) {
          if (coverMap.containsKey(frontCover)) {
            frontCoverIndex = coverMap[frontCover];
          } else {
            frontCoverIndex = uniqueFrontCovers.length;
            uniqueFrontCovers.add(frontCover);
            coverMap[frontCover] = frontCoverIndex;
          }
        }

        return MetadataBackupItem(
          path: track.path,
          frontCoverIndex: frontCoverIndex,
          metadata: track.metadata.toJson().toIMap(),
        );
      }).toIList();

      final backup = MetadataBackupModel(
        version: kBackupVersion,
        metadataList: metadataList,
        frontCovers: uniqueFrontCovers.map(base64Encode).toIList(),
      );
      final json = backup.toFormattedJson();
      await File(path).writeAsString(json, encoding: utf8);
      globalTalker.info('成功导出 ${tracks.length} 条音轨的元数据');
    } catch (e, st) {
      globalTalker.error('导出元数据失败', e, st);
      rethrow;
    }
  }
}

@riverpod
class MetadataImportUtil extends _$MetadataImportUtil {
  @override
  AsyncValue<MetadataBackupModel?> build() => const AsyncValue.data(null);

  Future<void> load() async {
    state = const AsyncValue.loading();

    try {
      final path = ref.read(pathProvider);
      if (path == null) {
        throw Exception('未选择导入文件');
      }

      final backup = await _import(path);
      state = AsyncValue.data(backup);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<MetadataBackupModel> _import(String path) async {
    try {
      final content = await File(path).readAsString(encoding: utf8);
      final json = jsonDecode(content) as Map<String, dynamic>;
      final backup = MetadataBackupModel.fromJson(json);
      globalTalker.info('成功加载备份文件, 包含 ${backup.metadataList.length} 条元数据');
      return backup;
    } catch (e, st) {
      globalTalker.error('加载备份文件失败', e, st);
      rethrow;
    }
  }
}

@riverpod
class MatchUtil extends _$MatchUtil {
  @override
  MatchState build() {
    final selectedTracks = ref.read(selectedTracksProvider);
    final backups = ref.read(metadataBackupProvider).metadataList;
    return _match(selectedTracks, backups);
  }

  void match() {
    final selectedTracks = ref.read(selectedTracksProvider);
    final backups = ref.read(metadataBackupProvider).metadataList;
    state = _match(selectedTracks, backups);
  }

  MatchState _match(IList<Track> tracks, IList<MetadataBackupItem> backups) {
    final matches = <int, IList<int>>{};

    for (var i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final trackFilename = p.basenameWithoutExtension(track.path);
      final trackTitle = track.metadata.title;
      final trackMatches = <int>[]; // 可能一对多

      for (var j = 0; j < backups.length; j++) {
        final backupPath = backups[j].path;
        final backupFilename = p.basenameWithoutExtension(backupPath);
        final backupTitle = backups[j].metadata['title'] as String?;

        if (trackFilename == backupFilename) {
          trackMatches.add(j);
          continue;
        }
        if (backupTitle != null &&
            _hasCommonSubstring(trackFilename, backupTitle)) {
          trackMatches.add(j);
        }

        if (trackTitle != null &&
            _hasCommonSubstring(trackTitle, backupFilename)) {
          trackMatches.add(j);
        }

        if (trackTitle != null &&
            backupTitle != null &&
            _hasCommonSubstring(trackTitle, backupTitle)) {
          trackMatches.add(j);
        }
      }
      matches[i] = trackMatches.toIList();
    }

    final result = _resolveMatches(matches.toIMap());
    return MatchState(candidates: matches.toIMap(), result: result);
  }

  void updateMatch(int trackIndex, int? backupIndex) {
    final result = MatchResult(
      matches: backupIndex != null
          ? state.result.matches.remove(trackIndex).add(trackIndex, backupIndex)
          : state.result.matches.remove(trackIndex),
      conflicts: state.result.conflicts.remove(trackIndex),
    );
    state = state.copyWith(result: result);
  }

  void clear() {
    state = state.copyWith(
      result: const MatchResult(
        matches: IMapConst(<int, int>{}),
        conflicts: ISetConst(<int>{}),
      ),
    );
  }

  void sequentialMatch() {
    final selectedTracks = ref.read(selectedTracksProvider);
    final backups = ref.read(metadataBackupProvider).metadataList;

    assert(selectedTracks.length == backups.length);

    final matches = <int, int>{};
    for (var i = 0; i < selectedTracks.length; i++) {
      matches[i] = i;
    }

    final result = MatchResult(
      matches: matches.toIMap(),
      conflicts: const ISetConst(<int>{}),
    );

    state = MatchState(
      candidates: matches.map((k, v) => MapEntry(k, [v].toIList())).toIMap(),
      result: result,
    );
  }

  Future<void> apply(MatchResult result, MetadataBackupModel backup) async {
    try {
      final selectedTracks = ref.read(selectedTracksProvider);
      final updatedTracks = _apply(selectedTracks, result, backup);
      final playlistId = ref.read(playlistIdProvider).selectedId;
      ref
          .read(playlistsProvider.notifier)
          .updateTracks(playlistId, updatedTracks);
      globalTalker.info('成功应用 ${result.matches.length} 条元数据匹配');
    } catch (e, st) {
      globalTalker.error('应用元数据匹配失败', e, st);
      rethrow;
    }
  }

  IList<Track> _apply(
    IList<Track> tracks,
    MatchResult result,
    MetadataBackupModel backup,
  ) {
    return tracks.asMap().entries.map((e) {
      final index = e.key;
      final track = e.value;
      final backupIndex = result.matches[index];

      if (backupIndex == null) return track;

      final backupItem = backup.metadataList[backupIndex];
      final metadataMap = backupItem.metadata;

      Uint8List? frontCover;
      if (backupItem.frontCoverIndex != null &&
          backupItem.frontCoverIndex! < backup.frontCovers.length) {
        try {
          frontCover = base64Decode(
            backup.frontCovers[backupItem.frontCoverIndex!],
          );
        } catch (e) {
          globalTalker.warning('解码封面失败: $e');
        }
      }

      return track.copyWith(
        metadata: Metadata(
          title: metadataMap['title'] as String?,
          artist: metadataMap['artist'] as String?,
          album: metadataMap['album'] as String?,
          albumArtist: metadataMap['albumartist'] as String?,
          trackNumber: metadataMap['tracknumber'] as int?,
          trackTotal: metadataMap['tracktotal'] as int?,
          discNumber: metadataMap['discnumber'] as int?,
          discTotal: metadataMap['disctotal'] as int?,
          date: metadataMap['date'] as String?,
          genre: metadataMap['genre'] as String?,
          frontCover: frontCover,
        ),
        pendingWriteback: true,
      );
    }).toIList();
  }

  bool _hasCommonSubstring(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return false;
    if (str1.length < kMinLength || str2.length < kMinLength) return false;

    final n = str1.length;
    final m = str2.length;

    var dp = List.filled(m + 1, 0);

    for (var i = 1; i <= n; i++) {
      var prev = 0;
      for (var j = 1; j <= m; j++) {
        final temp = dp[j];
        if (str1[i - 1] == str2[j - 1]) {
          dp[j] = prev + 1;
          if (dp[j] >= kMinLength) {
            return true;
          }
        } else {
          dp[j] = 0;
        }
        prev = temp;
      }
    }

    return false;
  }

  MatchResult _resolveMatches(IMap<int, IList<int>> matches) {
    var resolvedMatches = <int, int>{}.toIMap();
    var conflicts = <int>{}.toISet();

    for (final entry in matches.entries) {
      final trackIndex = entry.key;
      final backupIndexes = entry.value;

      if (backupIndexes.length == 1) {
        final backupIndex = backupIndexes.first;
        final competingTracks = matches.entries
            .where((e) => e.value.contains(backupIndex))
            .map((e) => e.key)
            .toList();

        if (competingTracks.length == 1) {
          resolvedMatches = resolvedMatches.add(trackIndex, backupIndex);
        }
      }
    }

    for (final entry in matches.entries) {
      final trackIndex = entry.key;
      if (!resolvedMatches.containsKey(trackIndex)) {
        conflicts = conflicts.add(trackIndex);
      }
    }

    return MatchResult(matches: resolvedMatches, conflicts: conflicts);
  }
}
