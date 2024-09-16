import 'dart:convert';
import 'dart:ui';

import 'package:flubar/app/settings/util.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
String settingsString(SettingsStringRef ref) => throw UnimplementedError();

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  SettingsModel build() {
    final str = ref.read(settingsStringProvider);
    final settings = (() {
      const defaultSettings = SettingsModel();
      try {
        final loadedSettings = SettingsModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          darkMode: loadedSettings.darkMode,
          ffmpegPath: loadedSettings.ffmpegPath,
          fileNameTpl: loadedSettings.fileNameTpl,
          forceWriteMetadata: loadedSettings.forceWriteMetadata,
          transcodeFormat: loadedSettings.transcodeFormat,
          isolateCount: loadedSettings.isolateCount,
          mp3Bitrate: loadedSettings.mp3Bitrate,
          flacCompressionLevel: loadedSettings.flacCompressionLevel,
          wavEncoder: loadedSettings.wavEncoder,
          rememberTranscodeChoice: loadedSettings.rememberTranscodeChoice,
          overwriteExistingFiles: loadedSettings.overwriteExistingFiles,
          windowWidth: loadedSettings.windowWidth,
          windowHeight: loadedSettings.windowHeight,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析设置文件: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateDarkMode(bool darkMode) =>
      state = state.copyWith(darkMode: darkMode);

  void updateFfmpegPath(String ffmpegPath) =>
      state = state.copyWith(ffmpegPath: ffmpegPath);

  void updateFileNameTpl(String fileNameTpl) =>
      state = state.copyWith(fileNameTpl: fileNameTpl);

  void updateForceWriteMetadata(bool forceWriteMetadata) =>
      state = state.copyWith(forceWriteMetadata: forceWriteMetadata);

  void updateTranscodeFormat(TranscodeFormat transcodeFormat) =>
      state = state.copyWith(transcodeFormat: transcodeFormat);

  void updateIsolateCount(int isolateCount) =>
      state = state.copyWith(isolateCount: isolateCount);

  void updateMp3Bitrate(int mp3Bitrate) =>
      state = state.copyWith(mp3Bitrate: mp3Bitrate);

  void updateFlacCompressionLevel(int flacCompressionLevel) =>
      state = state.copyWith(flacCompressionLevel: flacCompressionLevel);

  void updateWavEncoder(FfmpegEncoder wavEncoder) =>
      state = state.copyWith(wavEncoder: wavEncoder);

  void updateRememberTranscodeChoice(bool rememberTranscodeChoice) =>
      state = state.copyWith(rememberTranscodeChoice: rememberTranscodeChoice);

  void updateOverwriteExistingFiles(bool overwriteExistingFiles) =>
      state = state.copyWith(overwriteExistingFiles: overwriteExistingFiles);

  void updateWindowSize(Size size) {
    state = state.copyWith(
      windowWidth: size.width,
      windowHeight: size.height,
    );
  }

  void saveSettings() =>
      ref.read(storageUtilProvider.notifier).writeSettingsSync(state);
}
