import 'dart:io';

import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/extensions/metadata_extension.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flubar/ui/dialogs/input_dialog/view.dart';
import 'package:flubar/ui/dialogs/slider_dialog/view.dart';
import 'package:flubar/ui/dialogs/transcode_fmt_dialog/view.dart';
import 'package:flubar/ui/dialogs/wav_encoder_dialog/view.dart';
import 'package:flubar/ui/widgets/setting_tile/view.dart';
import 'package:flubar/utils/template/providers.dart';
import 'package:flubar/utils/transcode/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart' hide SettingsTile;
import 'package:get/get.dart';
import 'package:riverpod/riverpod.dart';

import 'constants.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: const _SettingsListView(),
      ),
    );
  }
}

class _SettingsListView extends StatelessWidget {
  const _SettingsListView();

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      lightTheme: const SettingsThemeData(
        settingsListBackground: Colors.transparent,
      ),
      darkTheme: const SettingsThemeData(
        settingsListBackground: Colors.transparent,
      ),
      platform: DevicePlatform.linux,
      contentPadding: EdgeInsets.zero,
      sections: [
        SettingsSection(
          title: const Text('常规'),
          tiles: [
            SwitchSettingsTile<GeneralSettingsProvider, GeneralSettingsModel>(
              title: '深色模式',
              leading: const Icon(Icons.dark_mode),
              provider: generalSettingsProvider,
              selector: (state) => state.darkMode,
              onToggle: (ref, value) => ref
                  .read(generalSettingsProvider.notifier)
                  .updateDarkMode(value),
            ),
          ],
        ),
        SettingsSection(
          title: const Text('扫描'),
          tiles: [
            SwitchSettingsTile<ScanSettingsProvider, ScanSettingsModel>(
              title: 'CUE 作为播放列表',
              leading: const Icon(Icons.playlist_play),
              provider: scanSettingsProvider,
              selector: (state) => state.cueAsPlaylist,
              onToggle: (ref, value) => ref
                  .read(scanSettingsProvider.notifier)
                  .updateCueAsPlaylist(value),
            ),
          ],
        ),
        SettingsSection(
          title: const Text('元数据'),
          tiles: [
            SettingsTile<
              MetadataSettingsProvider,
              MetadataSettingsModel,
              String
            >(
              title: '文件名模板',
              description:
                  '可用项: %filename%, %title%, %artist%, %album%, %albumartist%, %tracknumber%, %tracktotal%, %discnumber%, %disctotal%, %date%, %genre%',
              leading: const Icon(Icons.text_fields),
              provider: metadataSettingsProvider,
              selector: (state) => state.fileNameTpl,
              onPressed: (ref, _) => Get.dialog(
                InputDialog(
                  dialogTitle: '文件名模板',
                  initialValue: ref.read(
                    metadataSettingsProvider.select(
                      (state) => state.fileNameTpl,
                    ),
                  ),
                  onConfirm: (value) => ref
                      .read(metadataSettingsProvider.notifier)
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
              leading: const SizedBox(width: 24),
              processValue: (ref, _) => ref
                  .read(tplUtilProvider)
                  .process(
                    metadata: kExampleTrack.metadata,
                    path: kExampleTrack.path,
                  ),
            ),
          ],
        ),
        SettingsSection(
          title: const Text('转码'),
          tiles: [
            SettingsTile<
              TranscodeSettingsProvider,
              TranscodeSettingsModel,
              String
            >(
              title: 'FFmpeg 路径',
              leading: const Icon(Icons.insert_drive_file),
              provider: transcodeSettingsProvider,
              selector: (state) => state.ffmpegPath,
              onPressed: (ref, _) => Get.dialog(
                InputDialog(
                  dialogTitle: 'FFmpeg 路径',
                  initialValue: ref.read(
                    transcodeSettingsProvider.select(
                      (state) => state.ffmpegPath,
                    ),
                  ),
                  onConfirm: (value) => ref
                      .read(transcodeSettingsProvider.notifier)
                      .updateFfmpegPath(value),
                ),
              ),
            ),
            SettingsTile<
              TranscodeSettingsProvider,
              TranscodeSettingsModel,
              int
            >(
              title: 'Isolate 数量',
              leading: const Icon(Icons.device_hub),
              provider: transcodeSettingsProvider,
              selector: (state) => state.isolateCount,
              onPressed: (ref, _) {
                final int maxIsolates = Platform.numberOfProcessors;
                Get.dialog(
                  SliderDialog(
                    title: 'Isolate 数量',
                    min: 1,
                    max: maxIsolates.toDouble(),
                    divisions: maxIsolates - 1,
                    initialValue: ref.read(
                      transcodeSettingsProvider.select(
                        (state) => state.isolateCount,
                      ),
                    ),
                    onChanged: (value) => ref
                        .read(transcodeSettingsProvider.notifier)
                        .updateIsolateCount(value),
                    labelSuffix: ' 个',
                  ),
                );
              },
            ),
            SettingsTile<
              TranscodeSettingsProvider,
              TranscodeSettingsModel,
              String
            >(
              title: '转码格式',
              leading: const Icon(Icons.audio_file),
              provider: transcodeSettingsProvider,
              selector: (state) => state.transcodeFormat.displayName,
              onPressed: (ref, _) => Get.dialog(const TranscodeFormatDialog()),
            ),
            SettingsTile<
              TranscodeSettingsProvider,
              TranscodeSettingsModel,
              int
            >(
              title: 'MP3 比特率',
              leading: const Icon(Icons.equalizer, color: Colors.transparent),
              provider: transcodeSettingsProvider,
              selector: (state) => state.mp3Bitrate,
              onPressed: (ref, _) => Get.dialog(
                SliderDialog(
                  title: 'MP3 比特率',
                  min: kMp3BitrateMin.toDouble(),
                  max: kMp3BitrateMax.toDouble(),
                  divisions: kMp3BitrateDivisions,
                  initialValue: ref.read(
                    transcodeSettingsProvider.select(
                      (state) => state.mp3Bitrate,
                    ),
                  ),
                  onChanged: (value) => ref
                      .read(transcodeSettingsProvider.notifier)
                      .updateMp3Bitrate(value),
                  labelSuffix: ' kbps',
                ),
              ),
            ),
            SettingsTile<
              TranscodeSettingsProvider,
              TranscodeSettingsModel,
              int
            >(
              title: 'FLAC 压缩等级',
              leading: const Icon(Icons.equalizer, color: Colors.transparent),
              provider: transcodeSettingsProvider,
              selector: (state) => state.flacCompressionLevel,
              onPressed: (ref, _) => Get.dialog(
                SliderDialog(
                  title: 'FLAC 压缩等级',
                  min: 0,
                  max: kFlacCompressionLevelMax.toDouble(),
                  divisions: kFlacCompressionLevelMax,
                  initialValue: ref.read(
                    transcodeSettingsProvider.select(
                      (state) => state.flacCompressionLevel,
                    ),
                  ),
                  onChanged: (value) => ref
                      .read(transcodeSettingsProvider.notifier)
                      .updateFlacCompressionLevel(value),
                ),
              ),
            ),
            SettingsTile<
              TranscodeSettingsProvider,
              TranscodeSettingsModel,
              String
            >(
              title: 'WAV 编码器',
              leading: const Icon(Icons.equalizer, color: Colors.transparent),
              provider: transcodeSettingsProvider,
              selector: (state) => state.wavEncoder.displayName,
              onPressed: (ref, _) => Get.dialog(const WavEncoderDialog()),
            ),
          ],
        ),
        SettingsSection(
          title: const Text('转码警告'),
          tiles: [
            SwitchSettingsTile<
              TranscodeWarningsProvider,
              TranscodeWarningsModel
            >(
              title: '使用有损转码',
              leading: const SizedBox(width: 24),
              provider: transcodeWarningsProvider,
              selector: (state) => state.toLossy,
              onToggle: (ref, value) => ref
                  .read(transcodeWarningsProvider.notifier)
                  .updateToLossy(value),
            ),
            SwitchSettingsTile<
              TranscodeWarningsProvider,
              TranscodeWarningsModel
            >(
              title: '浮点数转整数',
              leading: const SizedBox(width: 24),
              provider: transcodeWarningsProvider,
              selector: (state) => state.floatToInt,
              onToggle: (ref, value) => ref
                  .read(transcodeWarningsProvider.notifier)
                  .updateFloatToInt(value),
            ),
            SwitchSettingsTile<
              TranscodeWarningsProvider,
              TranscodeWarningsModel
            >(
              title: '高位转低位',
              leading: const SizedBox(width: 24),
              provider: transcodeWarningsProvider,
              selector: (state) => state.highToLowBit,
              onToggle: (ref, value) => ref
                  .read(transcodeWarningsProvider.notifier)
                  .updateHighToLowBit(value),
            ),
          ],
        ),
      ],
    );
  }
}
