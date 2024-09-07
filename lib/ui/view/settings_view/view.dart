import 'dart:io';

import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/ui/dialogs/input_dialog/view.dart';
import 'package:flubar/ui/dialogs/slider_dialog/view.dart';
import 'package:flubar/ui/dialogs/transcode_fmt_dialog/view.dart';
import 'package:flubar/ui/dialogs/wav_encoder_dialog/view.dart';
import 'package:flubar/ui/view/settings_view/constants.dart';
import 'package:flubar/ui/widgets/setting_tile/view.dart';
import 'package:flubar/utils/template/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart' hide SettingsTile;
import 'package:get/get.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
        insetPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: const _SettingsListView(),
        ));
  }
}

class _SettingsListView extends ConsumerWidget {
  const _SettingsListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsList(
      lightTheme:
          const SettingsThemeData(settingsListBackground: Colors.transparent),
      darkTheme:
          const SettingsThemeData(settingsListBackground: Colors.transparent),
      platform: DevicePlatform.linux,
      contentPadding: EdgeInsets.zero,
      sections: [
        SettingsSection(
          title: const Text('常规'),
          tiles: [
            SwitchSettingsTile(
              title: '深色模式',
              leading: const Icon(Icons.dark_mode),
              selector: (state) => state.darkMode,
              onToggle: (value) =>
                  ref.read(settingsProvider.notifier).updateDarkMode(value),
            ),
          ],
        ),
        SettingsSection(
          title: const Text('转码'),
          tiles: [
            SettingsTile<String>(
              title: 'FFmpeg 路径',
              leading: const Icon(Icons.insert_drive_file),
              selector: (state) => state.ffmpegPath,
              onPressed: (_) => Get.dialog(
                InputDialog(
                  dialogTitle: 'FFmpeg 路径',
                  initialValue: ref.read(
                      settingsProvider.select((state) => state.ffmpegPath)),
                  onConfirm: (value) => ref
                      .read(settingsProvider.notifier)
                      .updateFfmpegPath(value),
                ),
              ),
            ),
            SettingsTile<int>(
              title: 'Isolate 数量',
              leading: const Icon(Icons.device_hub),
              selector: (state) => state.isolateCount,
              onPressed: (_) {
                final int maxIsolates = Platform.numberOfProcessors;
                Get.dialog(
                  SliderDialog(
                    title: 'Isolate 数量',
                    min: 1,
                    max: maxIsolates.toDouble(),
                    divisions: maxIsolates - 1,
                    initialValue: ref.read(
                        settingsProvider.select((state) => state.isolateCount)),
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .updateIsolateCount(value),
                    labelSuffix: ' 个',
                  ),
                );
              },
            ),
            SettingsTile<String>(
              title: '转码格式',
              leading: const Icon(Icons.audio_file),
              selector: (state) => state.transcodeFormat.displayName,
              onPressed: (_) => Get.dialog(const TranscodeFormatDialog()),
            ),
            SettingsTile<int>(
              title: 'MP3 比特率',
              leading: const Icon(Icons.equalizer, color: Colors.transparent),
              selector: (state) => state.mp3Bitrate,
              onPressed: (_) => Get.dialog(
                SliderDialog(
                  title: 'MP3 比特率',
                  min: 64,
                  max: 320,
                  divisions: 256 ~/ 64,
                  initialValue: ref.read(
                      settingsProvider.select((state) => state.mp3Bitrate)),
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .updateMp3Bitrate(value),
                  labelSuffix: ' kbps',
                ),
              ),
            ),
            SettingsTile<int>(
              title: 'FLAC 压缩等级',
              leading: const Icon(Icons.equalizer, color: Colors.transparent),
              selector: (state) => state.flacCompressionLevel,
              onPressed: (_) => Get.dialog(
                SliderDialog(
                  title: 'FLAC 压缩等级',
                  min: 0,
                  max: 8,
                  divisions: 8,
                  initialValue: ref.read(settingsProvider
                      .select((state) => state.flacCompressionLevel)),
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .updateFlacCompressionLevel(value),
                ),
              ),
            ),
            // wavEncoder
            SettingsTile<String>(
              title: 'WAV 编码器',
              leading: const Icon(Icons.equalizer, color: Colors.transparent),
              selector: (state) => state.wavEncoder.displayName,
              onPressed: (_) => Get.dialog(const WavEncoderDialog()),
            ),
          ],
        ),
        SettingsSection(
          title: const Text('元数据'),
          tiles: [
            SettingsTile<String>(
              title: '文件名模板',
              description:
                  '可用项: %filename%, %title%, %artist%, %album%, %albumartist%, %tracknumber%, %tracktotal%, %discnumber%, %disctotal%, %year%, %genre%',
              leading: const Icon(Icons.text_fields),
              selector: (state) => state.fileNameTpl,
              onPressed: (_) => Get.dialog(
                InputDialog(
                  dialogTitle: '文件名模板',
                  initialValue: ref.read(
                      settingsProvider.select((state) => state.fileNameTpl)),
                  onConfirm: (value) => ref
                      .read(settingsProvider.notifier)
                      .updateFileNameTpl(value),
                ),
              ),
            ),
            ExampleSettingsTile(
              title: '模板示例',
              description: {
                ...kExampleTrack.metadata.toJson(),
                'path': kExampleTrack.path,
              }.toString(),
              leading: const Icon(Icons.text_fields, color: Colors.transparent),
              selector: (state) => state.fileNameTpl,
              processValue: (value) => ref.read(tplUtilProvider).process(
                  metadata: kExampleTrack.metadata, path: kExampleTrack.path),
            ),
          ],
        ),
      ],
    );
  }
}
