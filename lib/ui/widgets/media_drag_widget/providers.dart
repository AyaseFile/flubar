import 'package:flubar/app/talker.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/extensions/properties_extension.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/cue.dart';
import 'package:flubar/rust/api/ffmpeg.dart';
import 'package:flubar/rust/api/models.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
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

@riverpod
class MediaDragState extends _$MediaDragState {
  @override
  bool build() => false;

  Future<void> addFiles(Iterable<String> paths) async {
    final id = ref.read(playlistIdProvider).selectedId;
    final maxTrackIdNotifier = ref.read(maxTrackIdProvider.notifier);
    final playlistsNotifier = ref.read(playlistsProvider.notifier);

    var failed = 0;
    final results = await Future.wait(
      paths.map((path) async {
        try {
          final ext = p.extension(path);
          if (ext == '.cue') {
            final List<(String, Metadata, Properties)> cueTracks =
                await cueReadFile(file: path);
            return cueTracks.map((e) {
              final (cueAudio, metadata, properties) = e;
              globalTalker.debug(
                  '文件: $cueAudio, 元数据: ${metadata.toJson()}, 属性: ${properties.toJson()}');
              return Track(
                id: maxTrackIdNotifier.nextId(),
                path: cueAudio,
                metadata: metadata,
                properties: properties,
              );
            }).toList();
          } else {
            final (metadata, properties) = await readFile(file: path);
            globalTalker.debug(
                '文件: $path, 元数据: ${metadata.toJson()}, 属性: ${properties.toJson()}');
            return [
              Track(
                id: maxTrackIdNotifier.nextId(),
                path: path,
                metadata: metadata,
                properties: properties,
              )
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
            )
          ];
        }
      }),
      eagerError: false,
    );

    final tracks = results.expand((tracks) => tracks);
    playlistsNotifier.addTracks(id, tracks);
    if (failed != 0) {
      showExceptionSnackbar(title: '错误', message: '无法读取 $failed 个文件');
    }
  }

  void setDragging(bool dragging) {
    state = dragging;
  }
}
