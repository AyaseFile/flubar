import 'package:file_picker/file_picker.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flubar/ui/dialogs/ratio_dialog/view.dart';
import 'package:flubar/ui/snackbar/view.dart';
import 'package:flubar/utils/warnings/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'constants.dart';
import 'providers.dart';

class TranscodeDialog extends ConsumerWidget {
  const TranscodeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(transcodeFailedCountProvider);
    return const _TranscodeDialog();
  }
}

class _TranscodeDialog extends ConsumerWidget {
  const _TranscodeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcodeState = ref.watch(transcodeProvider);
    return RatioAlertDialog(
      title: const Row(children: [Text('转码'), Spacer(), _WarningIcon()]),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TranscodeSettings(),
          const SizedBox(height: 16 + kSettingRowVerticalPadding),
          const _CommandField(),
          const SizedBox(height: 16),
          if (transcodeState.isLoading) ...[
            Center(
              child: Column(
                children: [
                  Consumer(builder: (context, ref, _) {
                    final progress = ref.watch(transcodeProgressProvider);
                    return Column(
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text('${(progress * 100).toStringAsFixed(2)}%'),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  const Text('正在转码...'),
                ],
              ),
            )
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: transcodeState.isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: transcodeState.isLoading
              ? () => ref.read(transcodeProvider.notifier).cancelTranscode()
              : () async {
                  await ref.read(transcodeProvider.notifier).transcodeFiles();
                  final failedCount = ref.read(transcodeFailedCountProvider);
                  if (failedCount != -1) {
                    if (failedCount > 0) {
                      showExceptionSnackbar(
                          title: '转码操作失败', message: '$failedCount 个文件转码失败');
                    } else {
                      showSnackbar(title: '转码操作成功', message: '所有文件转码成功');
                    }
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
          autofocus: true,
          child:
              transcodeState.isLoading ? const Text('停止') : const Text('开始转码'),
        ),
      ],
    );
  }
}

class _TranscodeSettings extends StatelessWidget {
  const _TranscodeSettings();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingRow(label: '输出格式', child: _TranscodeFormatSelector()),
        _SettingRow(
          label: '输出位置',
          child: Row(children: [
            _OutputDirectorySelector(),
            SizedBox(width: kSpaceBetweenItems),
            _OverwriteExistingFilesCheckbox(),
            SizedBox(width: kSpaceBetweenItems),
            _DeleteOriginalFilesCheckbox(),
          ]),
        ),
        _SettingRow(
          label: '附加选项',
          child: Row(children: [
            _ClearMetadataCheckbox(),
            SizedBox(width: kSpaceBetweenItems),
            _KeepAudioOnlyCheckbox(),
            SizedBox(width: kSpaceBetweenItems),
            _RewriteMetadataCheckbox(),
            SizedBox(width: kSpaceBetweenItems),
            _RewriteFrontCoverCheckbox(),
          ]),
        ),
        _TranscodeOptionsSelector(),
        _SettingRow(label: '输出文件名模板', child: _TplField()),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;
  final bool expandChild;

  const _SettingRow({
    required this.label,
    required this.child,
    this.expandChild = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSettingRowVerticalPadding),
      child: Row(
        children: [
          SizedBox(
            width: kSettingRowLabelWidth,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: kSettingRowHorizontalSpacing),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class _TranscodeFormatSelector extends ConsumerWidget {
  const _TranscodeFormatSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(transcodeFmtProvider);
    return Row(
      children: [
        SizedBox(
          width: kTranscodeFormatDropdownWidth,
          child: DropdownButton<TranscodeFormat>(
            value: fmt,
            isExpanded: true,
            onChanged: (value) =>
                ref.read(transcodeFmtProvider.notifier).setFormat(value!),
            items: TranscodeFormat.values
                .map((format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.displayName,
                          style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: kSpaceBetweenItems),
        const _RememberChoiceCheckbox(),
      ],
    );
  }
}

class _RememberChoiceCheckbox extends ConsumerWidget {
  const _RememberChoiceCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '记住选择',
      value: ref.watch(rememberTranscodeChoiceProvider),
      onChanged: (_) =>
          ref.read(rememberTranscodeChoiceProvider.notifier).toggle(),
    );
  }
}

class _UseOriginalDirectoryCheckbox extends ConsumerWidget {
  const _UseOriginalDirectoryCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '使用原目录',
      value: ref.watch(useOriginalDirectoryProvider),
      onChanged: (_) =>
          ref.read(useOriginalDirectoryProvider.notifier).toggle(),
    );
  }
}

class _OutputDirectorySelector extends ConsumerWidget {
  const _OutputDirectorySelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useOriginal = ref.watch(useOriginalDirectoryProvider);
    final outputDir = ref.watch(outputDirectoryProvider);
    return Row(
      children: [
        const _UseOriginalDirectoryCheckbox(),
        if (!useOriginal) ...[
          const SizedBox(width: kSpaceBetweenItems),
          ElevatedButton(
            onPressed: () async {
              final selectedDir = await FilePicker.platform.getDirectoryPath();
              if (selectedDir != null) {
                ref
                    .read(outputDirectoryProvider.notifier)
                    .setDirectory(selectedDir);
              }
            },
            child: const Text('选择目录'),
          ),
          const SizedBox(width: kSpaceBetweenItems),
          Expanded(
            child: Text(
              outputDir ?? "未选择输出目录",
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _Checkbox extends ConsumerWidget {
  final String label;
  final bool value;
  final void Function(bool?) onChanged;

  const _Checkbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = !ref.watch(transcodeProvider).isLoading;
    return Row(
      children: [
        Checkbox(value: value, onChanged: enabled ? onChanged : null),
        Text(label),
      ],
    );
  }
}

class _OverwriteExistingFilesCheckbox extends ConsumerWidget {
  const _OverwriteExistingFilesCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '覆盖已有文件',
      value: ref.watch(overwriteExistingFilesProvider),
      onChanged: (_) =>
          ref.read(overwriteExistingFilesProvider.notifier).toggle(),
    );
  }
}

class _DeleteOriginalFilesCheckbox extends ConsumerWidget {
  const _DeleteOriginalFilesCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '删除原文件',
      value: ref.watch(deleteOriginalFilesProvider),
      onChanged: (_) => ref.read(deleteOriginalFilesProvider.notifier).toggle(),
    );
  }
}

class _ClearMetadataCheckbox extends ConsumerWidget {
  const _ClearMetadataCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '清除元数据',
      value: ref.watch(clearMetadataProvider),
      onChanged: (value) =>
          ref.read(clearMetadataProvider.notifier).set(value!),
    );
  }
}

class _KeepAudioOnlyCheckbox extends ConsumerWidget {
  const _KeepAudioOnlyCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '仅保留音频',
      value: ref.watch(keepAudioOnlyProvider),
      onChanged: (value) =>
          ref.read(keepAudioOnlyProvider.notifier).set(value!),
    );
  }
}

class _RewriteMetadataCheckbox extends ConsumerWidget {
  const _RewriteMetadataCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '重写元数据',
      value: ref.watch(rewriteMetadataProvider),
      onChanged: (value) =>
          ref.read(rewriteMetadataProvider.notifier).set(value!),
    );
  }
}

class _RewriteFrontCoverCheckbox extends ConsumerWidget {
  const _RewriteFrontCoverCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Checkbox(
      label: '重写封面',
      value: ref.watch(rewriteFrontCoverProvider),
      onChanged: (value) =>
          ref.read(rewriteFrontCoverProvider.notifier).set(value!),
    );
  }
}

class _TranscodeOptionsSelector extends ConsumerWidget {
  const _TranscodeOptionsSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(transcodeOptsProvider);
    return options.map(
      copy: (_) => const SizedBox(height: kSettingRowVerticalPadding * 2),
      mp3: (mp3) => _SettingRow(
        label: '码率',
        child: Row(
          children: [
            Expanded(
              child: Slider(
                min: 64,
                max: 320,
                divisions: 256 ~/ 64,
                value: mp3.bitrate.toDouble(),
                onChanged: (value) => ref
                    .read(transcodeOptsProvider.notifier)
                    .setMp3Options(bitrate: value.toInt()),
              ),
            ),
            SizedBox(
              width: kBitrateDisplayWidth,
              child: Text('${mp3.bitrate} kbps'),
            ),
          ],
        ),
      ),
      flac: (flac) => _SettingRow(
        label: '压缩级别',
        child: Row(
          children: [
            Expanded(
              child: Slider(
                min: 0,
                max: 8,
                divisions: 8,
                value: flac.compressionLevel.toDouble(),
                onChanged: (value) => ref
                    .read(transcodeOptsProvider.notifier)
                    .setFlacOptions(compressionLevel: value.toInt()),
              ),
            ),
            SizedBox(
              width: kCompressionLevelDisplayWidth,
              child: Text(flac.compressionLevel.toString()),
            ),
          ],
        ),
      ),
      wavPack: (_) => const SizedBox(height: kSettingRowVerticalPadding * 2),
      wav: (wav) => _SettingRow(
        label: '编码器',
        expandChild: false,
        child: SizedBox(
          width: kEncoderDisplayWidth,
          child: DropdownButton<FfmpegEncoder>(
            value: wav.encoder,
            isExpanded: true,
            onChanged: (value) => ref
                .read(transcodeOptsProvider.notifier)
                .setWavOptions(encoder: value!),
            items: FfmpegEncoder.values
                .map((encoder) => DropdownMenuItem(
                      value: encoder,
                      child: Text(encoder.displayName,
                          style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _WarningIcon extends ConsumerWidget {
  const _WarningIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warning = ref.watch(transcodeWarningUtilProvider);
    return warning.isEmpty
        ? const SizedBox.shrink()
        : Tooltip(
            message: warning,
            child: const Icon(Icons.warning, color: Colors.orange),
          );
  }
}

class _CommandField extends HookConsumerWidget {
  const _CommandField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandController =
        useTextEditingController(text: ref.read(transcodeCmdProvider));

    ref.listen<String>(transcodeCmdProvider, (previous, next) {
      commandController.value = TextEditingValue(text: next);
    });

    return TextField(
      controller: commandController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'FFmpeg 命令',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _TplField extends HookConsumerWidget {
  const _TplField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tplController =
        useTextEditingController(text: ref.read(outputFileNameTplProvider));

    ref.listen<String>(outputFileNameTplProvider, (previous, next) {
      tplController.value = TextEditingValue(text: next);
    });

    return TextField(
      controller: tplController,
      onChanged: (value) =>
          ref.read(outputFileNameTplProvider.notifier).setTpl(value),
      decoration: const InputDecoration(
        labelText: '文件名模板',
        border: OutlineInputBorder(),
      ),
    );
  }
}
