import 'package:flubar/ui/dialogs/get_dialog/providers.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/utils/backup/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'export_dialog.dart';
import 'matching_dialog.dart';
import 'providers.dart';

class MetadataImportDialog extends StatelessWidget {
  const MetadataImportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入元数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final length = ref.watch(
                selectedTracksProvider.select((state) => state.length),
              );
              return Text('已选择 $length 条音轨');
            },
          ),
        ],
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final importState = ref.watch(metadataImportUtilProvider);
            return TextButton(
              onPressed: importState.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('取消'),
            );
          },
        ),
        _ImportButton(),
      ],
    );
  }
}

class _ImportButton extends ConsumerWidget {
  const _ImportButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(metadataImportUtilProvider);
    final void Function()? onPressed;
    final Widget child;

    if (importState.isLoading) {
      onPressed = null;
      child = const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      onPressed = () async {
        await selectFile(ref, pickFile: true);
        if (ref.read(pathProvider) == null) return;
        await ref.read(metadataImportUtilProvider.notifier).load();
        final importState = ref.read(metadataImportUtilProvider);
        final backup = importState.value!;
        ref.read(metadataBackupProvider.notifier).set(backup);
        if (context.mounted) {
          ref.watch(metadataBackupProvider);
          Navigator.of(context).pop();
          await ref
              .read(getDialogProvider.notifier)
              .show(const MetadataMatchingDialog(), barrierDismissible: false);
        }
      };
      child = const Text('选择文件');
    }

    return TextButton(onPressed: onPressed, autofocus: true, child: child);
  }
}
