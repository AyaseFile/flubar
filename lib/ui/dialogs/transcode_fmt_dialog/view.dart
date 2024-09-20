import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class TranscodeFormatDialog extends ConsumerWidget {
  const TranscodeFormatDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const fmtList = TranscodeFormat.values;
    return AlertDialog(
      title: const Text('转码格式'),
      content: SizedBox(
        width: double.minPositive,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: fmtList.length,
          itemBuilder: (context, index) {
            final fmt = fmtList[index];
            return ProviderScope(
              overrides: [selectionItemProvider.overrideWithValue(fmt)],
              child: const _SelectionItem(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final fmt = ref.read(selectionProvider);
            ref
                .read(transcodeSettingsProvider.notifier)
                .updateTranscodeFormat(fmt);
            Navigator.of(context).pop();
          },
          autofocus: true,
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _SelectionItem extends ConsumerWidget {
  const _SelectionItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final option = ref.watch(selectionItemProvider);
    final selected =
        ref.watch(selectionProvider.select((value) => value == option));
    return ListTile(
      title: Text(option.displayName),
      contentPadding: EdgeInsets.zero,
      leading: Consumer(builder: (context, ref, _) {
        final groupValue = ref.watch(selectionProvider);
        return Radio<TranscodeFormat>(
          value: option,
          groupValue: groupValue,
          onChanged: (value) =>
              ref.read(selectionProvider.notifier).select(value!),
        );
      }),
      selected: selected,
    );
  }
}
