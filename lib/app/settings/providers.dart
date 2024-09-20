import 'dart:convert';
import 'dart:ui';

import 'package:flubar/app/talker.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
Box settingsBox(SettingsBoxRef ref) => throw UnimplementedError();

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  late final Box _box;

  @override
  void build() => _box = ref.read(settingsBoxProvider);

  String getJson(String key) {
    return (_box.get(key) as String?) ?? '{}';
  }

  void saveJson(String key, Map<String, dynamic> value) {
    _box.put(key, jsonEncode(value));
  }
}

@Riverpod(keepAlive: true)
class GeneralSettings extends _$GeneralSettings {
  @override
  GeneralSettingsModel build() {
    final settings = (() {
      final str = ref.read(settingsProvider.notifier).getJson('general');
      const defaultSettings = GeneralSettingsModel();
      try {
        final loadedSettings = GeneralSettingsModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          darkMode: loadedSettings.darkMode,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析常规设置: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateDarkMode(bool darkMode) {
    state = state.copyWith(darkMode: darkMode);
    _save();
  }

  void _save() =>
      ref.read(settingsProvider.notifier).saveJson('general', state.toJson());
}

@Riverpod(keepAlive: true)
class MetadataSettings extends _$MetadataSettings {
  @override
  MetadataSettingsModel build() {
    final settings = (() {
      final str = ref.read(settingsProvider.notifier).getJson('metadata');
      const defaultSettings = MetadataSettingsModel();
      try {
        final loadedSettings = MetadataSettingsModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          forceWriteMetadata: loadedSettings.forceWriteMetadata,
          fileNameTpl: loadedSettings.fileNameTpl,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析元数据设置: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateForceWriteMetadata(bool forceWriteMetadata) {
    state = state.copyWith(forceWriteMetadata: forceWriteMetadata);
    _save();
  }

  void updateFileNameTpl(String fileNameTpl) {
    state = state.copyWith(fileNameTpl: fileNameTpl);
    _save();
  }

  void _save() =>
      ref.read(settingsProvider.notifier).saveJson('metadata', state.toJson());
}

@Riverpod(keepAlive: true)
class TranscodeSettings extends _$TranscodeSettings {
  @override
  TranscodeSettingsModel build() {
    final settings = (() {
      final str = ref.read(settingsProvider.notifier).getJson('transcode');
      const defaultSettings = TranscodeSettingsModel();
      try {
        final loadedSettings = TranscodeSettingsModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          ffmpegPath: loadedSettings.ffmpegPath,
          isolateCount: loadedSettings.isolateCount,
          transcodeFormat: loadedSettings.transcodeFormat,
          mp3Bitrate: loadedSettings.mp3Bitrate,
          flacCompressionLevel: loadedSettings.flacCompressionLevel,
          wavEncoder: loadedSettings.wavEncoder,
          rememberTranscodeChoice: loadedSettings.rememberTranscodeChoice,
          overwriteExistingFiles: loadedSettings.overwriteExistingFiles,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析转码设置: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateFfmpegPath(String ffmpegPath) {
    state = state.copyWith(ffmpegPath: ffmpegPath);
    _save();
  }

  void updateIsolateCount(int isolateCount) {
    state = state.copyWith(isolateCount: isolateCount);
    _save();
  }

  void updateTranscodeFormat(TranscodeFormat transcodeFormat) {
    state = state.copyWith(transcodeFormat: transcodeFormat);
    _save();
  }

  void updateMp3Bitrate(int mp3Bitrate) {
    state = state.copyWith(mp3Bitrate: mp3Bitrate);
    _save();
  }

  void updateFlacCompressionLevel(int flacCompressionLevel) {
    state = state.copyWith(flacCompressionLevel: flacCompressionLevel);
    _save();
  }

  void updateWavEncoder(FfmpegEncoder wavEncoder) {
    state = state.copyWith(wavEncoder: wavEncoder);
    _save();
  }

  void updateRememberTranscodeChoice(bool rememberTranscodeChoice) {
    state = state.copyWith(rememberTranscodeChoice: rememberTranscodeChoice);
    _save();
  }

  void updateOverwriteExistingFiles(bool overwriteExistingFiles) {
    state = state.copyWith(overwriteExistingFiles: overwriteExistingFiles);
    _save();
  }

  void _save() =>
      ref.read(settingsProvider.notifier).saveJson('transcode', state.toJson());
}

@Riverpod(keepAlive: true)
class TranscodeWarnings extends _$TranscodeWarnings {
  @override
  TranscodeWarningsModel build() {
    final settings = (() {
      final str =
          ref.read(settingsProvider.notifier).getJson('transcodeWarnings');
      const defaultSettings = TranscodeWarningsModel();
      try {
        final loadedSettings = TranscodeWarningsModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          toLossy: loadedSettings.toLossy,
          floatToInt: loadedSettings.floatToInt,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析转码警告设置: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateToLossy(bool toLossy) {
    state = state.copyWith(toLossy: toLossy);
    _save();
  }

  void updateFloatToInt(bool floatToInt) {
    state = state.copyWith(floatToInt: floatToInt);
    _save();
  }

  void _save() => ref
      .read(settingsProvider.notifier)
      .saveJson('transcodeWarnings', state.toJson());
}

@riverpod
WindowSettingsModel windowSettingsLoaded(WindowSettingsLoadedRef ref) =>
    throw UnimplementedError();

@Riverpod(keepAlive: true)
class WindowSettings extends _$WindowSettings {
  @override
  WindowSettingsModel build() => ref.read(windowSettingsLoadedProvider);

  void updateWindowSize(Size size) {
    state = state.copyWith(width: size.width, height: size.height);
    _save();
  }

  void _save() =>
      ref.read(settingsProvider.notifier).saveJson('window', state.toJson());
}
