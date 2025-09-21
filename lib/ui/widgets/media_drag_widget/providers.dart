import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/models/state/playlist.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/cue.dart';
import 'package:flubar/rust/api/lofty.dart';
import 'package:flubar/rust/api/models.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:flubar/ui/widgets/menu_bar_widget/constants.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
class EnableMediaDrag extends _$EnableMediaDrag {
  @override
  bool build() => true;

  void enable() {
    state = true;
  }

  void disable() {
    state = false;
  }
}

enum DragBehavior { filesOnly, recursive }

@riverpod
class MediaDragState extends _$MediaDragState {
  @override
  bool build() => false;

  Future<void> addFiles(
    Iterable<String> paths, {
    DragBehavior behavior = DragBehavior.recursive,
  }) async {
    final id = ref.read(playlistIdProvider).selectedId;
    final maxTrackIdNotifier = ref.read(maxTrackIdProvider.notifier);
    final playlistsNotifier = ref.read(playlistsProvider.notifier);

    final filePaths = await switch (behavior) {
      DragBehavior.filesOnly => Future.value(paths),
      DragBehavior.recursive => Future.wait(
        paths.map(
          (path) async => await FileSystemEntity.isDirectory(path)
              ? await _getMediaFiles(path)
              : [path],
        ),
      ).then((lists) => lists.expand((x) => x)),
    };

    var failed = 0;
    final results = await Future.wait(
      filePaths.map((path) async {
        try {
          final ext = p.extension(path).toLowerCase();
          if (ext == '.cue') {
            final cueTracks = await cueReadFile(file: path);
            return cueTracks.map((e) {
              final (cueAudio, metadata, properties) = e;
              globalTalker.debug(
                '文件: $cueAudio, 元数据: ${metadata.toJson()}, 属性: ${properties.toJson()}',
              );
              return Track(
                id: maxTrackIdNotifier.nextId(),
                path: cueAudio,
                metadata: metadata,
                properties: properties,
              );
            }).toList();
          } else {
            final (metadata, properties) = await readHybrid(file: path);
            globalTalker.debug(
              '文件: $path, 元数据: ${metadata.toJson()}, 属性: ${properties.toJson()}',
            );
            return [
              Track(
                id: maxTrackIdNotifier.nextId(),
                path: path,
                metadata: metadata,
                properties: properties,
              ),
            ];
          }
        } catch (e) {
          failed++;
          globalTalker.error('无法读取文件: $path', e, null);
          return [
            Track(
              id: maxTrackIdNotifier.nextId(),
              metadata: const Metadata(),
              properties: const Properties(),
              path: path,
            ),
          ];
        }
      }),
      eagerError: false,
    );

    final tracks = results.expand((tracks) => tracks);
    final cueAsPlaylist = ref.read(scanSettingsProvider).cueAsPlaylist;
    if (cueAsPlaylist) {
      final (audioTracks, cueTracksByPath) = tracks
          .fold<(List<Track>, Map<String, List<Track>>)>(([], {}), (
            acc,
            track,
          ) {
            final (audioList, cueMap) = acc;
            if (track.properties.isCue()) {
              (cueMap[track.path] ??= []).add(track);
            } else {
              audioList.add(track);
            }
            return (audioList, cueMap);
          });

      if (audioTracks.isNotEmpty) {
        playlistsNotifier.addTracks(id, audioTracks);
      }

      if (cueTracksByPath.isNotEmpty) {
        playlistsNotifier.addPlaylists(
          cueTracksByPath.entries.map((entry) {
            final cueTracks = entry.value;
            return Playlist(
              id: maxTrackIdNotifier.nextId(),
              name: cueTracks.first.metadata.album ?? '未知专辑',
              tracks: cueTracks.toIList(),
            );
          }),
        );
      }
    } else {
      playlistsNotifier.addTracks(id, tracks);
    }

    if (failed != 0) {
      showExceptionSnackbar(title: '错误', message: '无法读取 $failed 个文件');
    }
  }

  Future<List<String>> _getMediaFiles(String path) async {
    final entity = Directory(path);
    final dirFiles = <String, List<String>>{};
    final dirCues = <String, List<String>>{};

    try {
      await for (final file in entity.list(recursive: true)) {
        if (file is File) {
          final dir = p.dirname(file.path);
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.cue') {
            dirCues.putIfAbsent(dir, () => []).add(file.path);
          } else if (_isAudioFile(file.path)) {
            dirFiles.putIfAbsent(dir, () => []).add(file.path);
          }
        }
      }
    } catch (e) {
      globalTalker.error('遍历文件夹失败: $path', e, null);
    }

    final result = <String>[];
    for (final dir in dirFiles.keys) {
      if (dirCues.containsKey(dir)) {
        result.addAll(dirCues[dir]!);
      } else {
        result.addAll(dirFiles[dir]!);
      }
    }

    return result;
  }

  bool _isAudioFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext.isNotEmpty && kAudioExtensionsSet.contains(ext.substring(1));
  }

  void setDragging(bool dragging) {
    state = dragging;
  }
}
