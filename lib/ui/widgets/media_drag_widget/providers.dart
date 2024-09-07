import 'package:cross_file/cross_file.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/ui/view/tracklist_view/providers.dart';
import 'package:flubar/utils/metadata/reader.dart';
import 'package:metadata_god/metadata_god.dart';
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

  Future<void> addFiles(List<XFile> files) async {
    final id = ref.read(playlistIdProvider).selectedId;
    final maxTrackIdNotifier = ref.read(maxTrackIdProvider.notifier);
    final playlistsNotifier = ref.read(playlistsProvider.notifier);

    var failed = 0;
    final results = await Future.wait(
      files.map((file) async {
        var metadata = await MetadataReader.read(file: file.path);
        if (metadata == null) {
          failed++;
          metadata = const Metadata(tagType: TagType.unknown);
        }
        final id = maxTrackIdNotifier.nextId();
        globalTalker.debug('文件: ${file.path}, 元数据: ${metadata.toJson()}');
        return Track(id: id, metadata: metadata, path: file.path);
      }),
      eagerError: false,
    );

    playlistsNotifier.addTracks(id, results);
    if (failed != 0) {
      showExceptionSnackbar(title: '错误', message: '无法读取 $failed 个文件的元数据');
    }
  }

  void setDragging(bool dragging) {
    state = dragging;
  }
}
