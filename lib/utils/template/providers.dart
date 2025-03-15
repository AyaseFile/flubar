import 'dart:io';
import 'dart:isolate';

import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/cancel_token/cancel_token.dart';
import 'package:flubar/models/isolate/mixin.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/dialogs/rename_dialog/providers.dart';
import 'package:flubar/ui/view/playlist_view/providers.dart';
import 'package:flubar/utils/template/template.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class TplUtil extends _$TplUtil with IsolateMixin<(String, String)> {
  final _newTracks = <Track>[];

  @override
  TemplateProcessor build() {
    ref.keepAlive(); // 只要被引用就不会被释放
    isolateTask ??= (List<dynamic> args) {
      final sendPort = args[0] as SendPort;
      final renameData = args[1] as List<(String, String)>;
      for (final (oldPath, newPath) in renameData) {
        try {
          final file = File(oldPath);
          file.renameSync(newPath);
          sendPort.send({'error': null});
        } catch (e, st) {
          sendPort.send({'error': '无法重命名文件 $oldPath', 'e': e, 'st': st});
        }
      }
    };
    return TemplateProcessor(ref
        .watch(metadataSettingsProvider.select((state) => state.fileNameTpl)));
  }

  void setTpl(String tpl) {
    state = TemplateProcessor(tpl);
  }

  void resetTpl() {
    state = TemplateProcessor(ref
        .read(metadataSettingsProvider.select((state) => state.fileNameTpl)));
  }

  @override
  List<(String, String)> getData() {
    final selectedTracks = ref.read(selectedTracksProvider);
    return selectedTracks.map((track) {
      final newName = state.process(metadata: track.metadata, path: track.path);
      final newPath = p.join(p.dirname(track.path), newName);
      _newTracks.add(track.copyWith(path: newPath));
      return (track.path, newPath);
    }).toList();
  }

  @override
  int getIsolateCount() =>
      ref.read(transcodeSettingsProvider.select((state) => state.isolateCount));

  @override
  void init() {}

  @override
  void onCancellation(CancelException e) => renameTalker
      .info('重命名操作已取消.${e.reason != null ? ' 原因: ${e.reason}' : ''}');

  @override
  void onCompletion(Duration duration) {
    final playlistId = ref.read(playlistIdProvider).selectedId;
    final updatedTracks = <Track>[];
    for (final track in _newTracks) {
      if (File(track.path).existsSync()) {
        updatedTracks.add(track);
      }
    }
    ref
        .read(playlistsProvider.notifier)
        .updateTracks(playlistId, updatedTracks);
    renameTalker.info(
        '成功重命名 ${updatedTracks.length}/${_newTracks.length} 个文件. 耗时: $duration');
    _newTracks.clear();
  }

  @override
  void onError(Object e, StackTrace st) =>
      renameTalker.handle(e, st, '重命名操作失败');

  @override
  void onIsolatesCompletion(List<Isolate> isolates) {
    for (final isolate in isolates) {
      isolate.kill();
    }
  }

  @override
  void onProgress(double progress) =>
      ref.read(renameProgressProvider.notifier).setProgress(progress);

  @override
  void onTaskError(String? error, Object? e, StackTrace? st) {
    ref.read(renameFailedCountProvider.notifier).increment();
    renameTalker.error(error, e, st);
  }
}
