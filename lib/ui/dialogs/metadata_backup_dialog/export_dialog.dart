import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/utils/backup/providers.dart';
import 'package:flubar/app/settings/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import 'providers.dart';

class MetadataExportDialog extends ConsumerWidget {
  const MetadataExportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pathProvider);
    return const _MetadataExportDialog();
  }
}

class _MetadataExportDialog extends ConsumerWidget {
  const _MetadataExportDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final length = ref.watch(
      selectedTracksProvider.select((state) => state.length),
    );
    final exportState = ref.watch(metadataExportUtilProvider);
    return AlertDialog(
      title: const Text('导出元数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('将导出 $length 条音轨的元数据')],
      ),
      actions: [
        TextButton(
          onPressed: exportState.isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: exportState.isLoading
              ? null
              : () async {
                  await selectFile(ref);
                  if (ref.read(pathProvider) == null) return;
                  await ref.read(metadataExportUtilProvider.notifier).export();
                  switch (exportState) {
                    case AsyncData<void>():
                      showSnackbar(title: '导出操作成功', message: '所有元数据导出成功');
                    case AsyncError<void>():
                      showExceptionSnackbar(
                        title: '导出操作失败',
                        message: '查看日志获取更多信息',
                      );
                    case AsyncLoading<void>():
                      throw UnimplementedError();
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
          autofocus: true,
          child: exportState.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(),
                  ),
                )
              : const Text('开始导出'),
        ),
      ],
    );
  }
}

Future<void> selectFile(WidgetRef ref, {bool pickFile = false}) async {
  final outputPath = ref.read(historyProvider).outputPath;
  final filename = _genFilename(ref.read(selectedTracksProvider));
  final filePath = await () async {
    if (pickFile) {
      return FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
            initialDirectory: outputPath,
          )
          .then((result) => result?.files.single.path);
    } else {
      return FilePicker.platform.saveFile(
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: outputPath,
      );
    }
  }();
  if (filePath != null) {
    final newPath = '${p.dirname(filePath)}${p.separator}';
    ref.read(historyProvider.notifier).updateOutputPath(newPath);
    ref.read(pathProvider.notifier).set(filePath);
  }
}

String _genFilename(IList<Track> selectedTracks) {
  final String prefix;
  final albumNames = selectedTracks
      .map((e) => e.metadata.album)
      .whereType<String>()
      .where((album) => album.isNotEmpty);
  if (albumNames.isNotEmpty) {
    final counts = albumNames.groupFoldBy<String, int>(
      (album) => album,
      (previous, album) => (previous ?? 0) + 1,
    );
    if (counts.isNotEmpty) {
      final maxCount = counts.values.max;
      prefix = counts.entries.firstWhere((e) => e.value == maxCount).key;
    } else {
      prefix = 'metadata';
    }
  } else {
    prefix = 'metadata';
  }
  final now = DateTime.now();
  return '${prefix}_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.json';
}
