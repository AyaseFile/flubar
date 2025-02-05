import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class RenameDialog extends ConsumerWidget {
  const RenameDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(renameFailedCountProvider);
    return const _RenameDialog();
  }
}

class _RenameDialog extends ConsumerWidget {
  const _RenameDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final length =
        ref.watch(selectedTracksProvider.select((state) => state.length));
    final tpl = ref
        .watch(metadataSettingsProvider.select((state) => state.fileNameTpl));
    final renameState = ref.watch(renameProvider);
    return AlertDialog(
      title: const Text('重命名'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('将使用模板 "$tpl" 重命名 $length 个文件'),
          const SizedBox(height: 16),
          if (renameState.isLoading) ...[
            Center(
              child: Column(
                children: [
                  Consumer(builder: (context, ref, _) {
                    final progress = ref.watch(renameProgressProvider);
                    return Column(
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text('${(progress * 100).toStringAsFixed(2)}%'),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  const Text('正在重命名文件...'),
                ],
              ),
            )
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              renameState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: renameState.isLoading
              ? () => ref.read(renameProvider.notifier).cancelRename()
              : () async {
                  await ref.read(renameProvider.notifier).renameFiles();
                  final failedCount = ref.read(renameFailedCountProvider);
                  if (failedCount != -1) {
                    if (failedCount > 0) {
                      showExceptionSnackbar(
                          title: '重命名操作失败', message: '$failedCount 个文件重命名失败');
                    } else {
                      showSnackbar(title: '重命名操作成功', message: '所有文件重命名成功');
                    }
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
          autofocus: true,
          child: renameState.isLoading ? const Text('停止') : const Text('确定'),
        ),
      ],
    );
  }
}
