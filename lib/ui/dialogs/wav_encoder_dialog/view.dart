import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class WavEncoderDialog extends ConsumerWidget {
  const WavEncoderDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const encoders = FfmpegEncoder.values;
    return AlertDialog(
      title: const Text('WAV 编码器'),
      content: SizedBox(
        width: double.minPositive,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: encoders.length,
          itemBuilder: (context, index) {
            final encoder = encoders[index];
            return ProviderScope(
              overrides: [encoderItemProvider.overrideWithValue(encoder)],
              child: const _EncoderItem(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final encoder = ref.read(encoderSelectionProvider);
            ref
                .read(transcodeSettingsProvider.notifier)
                .updateWavEncoder(encoder);
            Navigator.pop(context, encoder);
          },
          autofocus: true,
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _EncoderItem extends ConsumerWidget {
  const _EncoderItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encoder = ref.watch(encoderItemProvider);
    final selected =
        ref.watch(encoderSelectionProvider.select((state) => state == encoder));
    return ListTile(
      title: Text(encoder.displayName),
      contentPadding: EdgeInsets.zero,
      leading: Consumer(builder: (context, ref, _) {
        final groupValue = ref.watch(encoderSelectionProvider);
        return Radio<FfmpegEncoder>(
          value: encoder,
          groupValue: groupValue,
          onChanged: (value) =>
              ref.read(encoderSelectionProvider.notifier).select(value!),
        );
      }),
      selected: selected,
    );
  }
}
