import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flubar/app/talker.dart';
import 'package:flubar/models/state/advanced_column_state.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flubar/utils/transcode/transcode.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
Box settingsBox(Ref ref) => throw UnimplementedError();

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
class ScanSettings extends _$ScanSettings {
  @override
  ScanSettingsModel build() {
    final settings = (() {
      final str = ref.read(settingsProvider.notifier).getJson('scan');
      const defaultSettings = ScanSettingsModel();
      try {
        final loadedSettings = ScanSettingsModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          cueAsPlaylist: loadedSettings.cueAsPlaylist,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析扫描设置: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateCueAsPlaylist(bool cueAsPlaylist) {
    state = state.copyWith(cueAsPlaylist: cueAsPlaylist);
    _save();
  }

  void _save() =>
      ref.read(settingsProvider.notifier).saveJson('scan', state.toJson());
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
          writeToMemoryOnly: loadedSettings.writeToMemoryOnly,
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

  void updateWriteToMemoryOnly(bool writeToMemoryOnly) {
    state = state.copyWith(
      writeToMemoryOnly: writeToMemoryOnly,
      forceWriteMetadata: writeToMemoryOnly ? false : state.forceWriteMetadata,
    );
    _save();
  }

  void updateForceWriteMetadata(bool forceWriteMetadata) {
    state = state.copyWith(
      forceWriteMetadata: forceWriteMetadata,
      writeToMemoryOnly: forceWriteMetadata ? false : state.writeToMemoryOnly,
    );
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
          useOriginalDirectory: loadedSettings.useOriginalDirectory,
          overwriteExistingFiles: loadedSettings.overwriteExistingFiles,
          deleteOriginalFiles: loadedSettings.deleteOriginalFiles,
          clearMetadata: loadedSettings.clearMetadata,
          keepAudioOnly: loadedSettings.keepAudioOnly,
          rewriteMetadata: loadedSettings.rewriteMetadata,
          rewriteFrontCover: loadedSettings.rewriteFrontCover,
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

  void updateTranscodeDialogSettings({
    required TranscodeFormat transcodeFormat,
    required TranscodeOptions options,
    required bool rememberTranscodeChoice,
    required bool useOriginalDirectory,
    required bool overwriteExistingFiles,
    required bool deleteOriginalFiles,
    required bool clearMetadata,
    required bool keepAudioOnly,
    required bool rewriteMetadata,
    required bool rewriteFrontCover,
  }) {
    state = state.copyWith(
      transcodeFormat: transcodeFormat,
      mp3Bitrate: switch (options) {
        Mp3TranscodeOptions(:final bitrate) => bitrate,
        _ => state.mp3Bitrate,
      },
      flacCompressionLevel: switch (options) {
        FlacTranscodeOptions(:final compressionLevel) => compressionLevel,
        _ => state.flacCompressionLevel,
      },
      wavEncoder: switch (options) {
        WavTranscodeOptions(:final encoder) => encoder,
        _ => state.wavEncoder,
      },
      rememberTranscodeChoice: rememberTranscodeChoice,
      useOriginalDirectory: useOriginalDirectory,
      overwriteExistingFiles: overwriteExistingFiles,
      deleteOriginalFiles: deleteOriginalFiles,
      clearMetadata: clearMetadata,
      keepAudioOnly: keepAudioOnly,
      rewriteMetadata: rewriteMetadata,
      rewriteFrontCover: rewriteFrontCover,
    );
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
          highToLowBit: loadedSettings.highToLowBit,
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

  void updateHighToLowBit(bool highToLowBit) {
    state = state.copyWith(highToLowBit: highToLowBit);
    _save();
  }

  void _save() => ref
      .read(settingsProvider.notifier)
      .saveJson('transcodeWarnings', state.toJson());
}

@riverpod
WindowSettingsModel windowSettingsLoaded(Ref ref) => throw UnimplementedError();

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

@Riverpod(keepAlive: true)
class History extends _$History {
  @override
  HistoryModel build() {
    final settings = (() {
      final str = ref.read(settingsProvider.notifier).getJson('history');
      const defaultSettings = HistoryModel();
      try {
        final loadedSettings = HistoryModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          openPath: loadedSettings.openPath,
          outputPath: loadedSettings.outputPath,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析历史记录设置: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateOpenPath(String openPath) {
    state = state.copyWith(openPath: openPath);
    _save();
  }

  void updateOutputPath(String outputPath) {
    state = state.copyWith(outputPath: outputPath);
    _save();
  }

  void _save() =>
      ref.read(settingsProvider.notifier).saveJson('history', state.toJson());
}

@Riverpod(keepAlive: true)
class TableColumnState extends _$TableColumnState {
  @override
  TableColumnStateModel build() {
    final settings = (() {
      final str =
          ref.read(settingsProvider.notifier).getJson('tableColumnState');
      const defaultSettings = TableColumnStateModel();
      try {
        final loadedSettings = TableColumnStateModel.fromJson(
          jsonDecode(str) as Map<String, dynamic>,
        );
        return defaultSettings.copyWith(
          trackTableColumns: loadedSettings.trackTableColumns,
        );
      } catch (e) {
        globalTalker.handle(e, null, '无法解析表格列设置: $str');
        return defaultSettings;
      }
    })();
    return settings;
  }

  void updateTrackTableColumns(List<AdvancedColumnState> trackTableColumns) {
    state = state.copyWith(trackTableColumns: trackTableColumns);
    _save();
  }

  void _save() => ref
      .read(settingsProvider.notifier)
      .saveJson('tableColumnState', state.toJson());
}

Future<String?> getInitialDirectory(String? path) async {
  return path != null && await Directory(path).exists()
      ? path.endsWith(p.separator)
          ? path
          : '$path${p.separator}'
      : null;
}
