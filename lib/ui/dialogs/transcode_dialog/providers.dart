import 'package:ffmpeg_cli/ffmpeg_cli.dart';
import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/extensions/cli_command.dart';
import 'package:flubar/models/extensions/ffmpeg_command.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flubar/utils/transcode/providers.dart';
import 'package:flubar/utils/transcode/transcode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class TranscodeFmt extends _$TranscodeFmt {
  @override
  TranscodeFormat build() => ref.watch(
      transcodeSettingsProvider.select((state) => state.transcodeFormat));

  void setFormat(TranscodeFormat format) {
    state = format;
  }

  void saveFormat() {
    ref.read(transcodeSettingsProvider.notifier).updateTranscodeFormat(state);
  }
}

@riverpod
class TranscodeOpts extends _$TranscodeOpts {
  @override
  TranscodeOptions build() {
    final fmt = ref.watch(transcodeFmtProvider);
    switch (fmt) {
      case TranscodeFormat.copy:
        return const TranscodeOptions.copy();
      case TranscodeFormat.mp3:
        return TranscodeOptions.mp3(
            bitrate: ref.watch(
                transcodeSettingsProvider.select((state) => state.mp3Bitrate)));
      case TranscodeFormat.flac:
        return TranscodeOptions.flac(
            compressionLevel: ref.watch(transcodeSettingsProvider
                .select((state) => state.flacCompressionLevel)));
      case TranscodeFormat.wav:
        return TranscodeOptions.wav(
            encoder: ref.watch(
                transcodeSettingsProvider.select((state) => state.wavEncoder)));
    }
  }

  void setMp3Options({int? bitrate}) {
    state = TranscodeOptions.mp3(
        bitrate: bitrate ??
            ref.read(
                transcodeSettingsProvider.select((state) => state.mp3Bitrate)));
  }

  void setFlacOptions({int? compressionLevel}) {
    state = TranscodeOptions.flac(
        compressionLevel: compressionLevel ??
            ref.read(transcodeSettingsProvider
                .select((state) => state.flacCompressionLevel)));
  }

  void setWavOptions({FfmpegEncoder? encoder}) {
    state = TranscodeOptions.wav(
        encoder: encoder ??
            ref.read(
                transcodeSettingsProvider.select((state) => state.wavEncoder)));
  }

  void setOptions(TranscodeOptions options) {
    state = options;
  }

  void saveOptions() {
    state.map(
      copy: (_) {},
      mp3: (mp3) {
        ref
            .read(transcodeSettingsProvider.notifier)
            .updateMp3Bitrate(mp3.bitrate);
      },
      flac: (flac) {
        ref
            .read(transcodeSettingsProvider.notifier)
            .updateFlacCompressionLevel(flac.compressionLevel);
      },
      wav: (wav) {
        ref
            .read(transcodeSettingsProvider.notifier)
            .updateWavEncoder(wav.encoder);
      },
    );
  }
}

@riverpod
class TranscodeCmd extends _$TranscodeCmd {
  @override
  String build() {
    final options = ref.watch(transcodeOptsProvider);
    final ffmpegPath = ref
        .watch(transcodeSettingsProvider.select((state) => state.ffmpegPath));
    final overwrite = ref.watch(overwriteExistingFilesProvider);
    final clearMetadata = ref.watch(clearMetadataProvider);
    final command = TranscodeUtil.buildFfmpegCommand(
      ffmpegPath: ffmpegPath,
      options: options,
      overwriteExistingFiles: overwrite,
      clearMetadata: clearMetadata,
    ).copyWith(
      inputs: [FfmpegInput.asset('{input_file}')],
      outputFilepath: '{output_file}',
    );
    return command.toCli().preview();
  }
}

@riverpod
class TranscodeProgress extends _$TranscodeProgress {
  @override
  double build() => 0.0;

  void setProgress(double progress) => state = progress;
}

@riverpod
class Transcode extends _$Transcode {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> transcodeFiles() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(transcodeUtilProvider.notifier).performTasks();
    });
  }

  void cancelTranscode() =>
      ref.read(transcodeUtilProvider.notifier).cancelTasks();
}

@riverpod
class OutputDirectory extends _$OutputDirectory {
  @override
  String? build() => null;

  void setDirectory(String? path) => state = path;
}

@riverpod
class UseOriginalDirectory extends _$UseOriginalDirectory {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

@riverpod
class TranscodeFailedCount extends _$TranscodeFailedCount {
  @override
  int build() => 0;

  void increment() => state++;

  void setCancelled() => state = -1;
}

@riverpod
class OverwriteExistingFiles extends _$OverwriteExistingFiles {
  @override
  bool build() => ref.watch(transcodeSettingsProvider
      .select((state) => state.overwriteExistingFiles));

  void toggle() => state = !state;

  void save() => ref
      .read(transcodeSettingsProvider.notifier)
      .updateOverwriteExistingFiles(state);
}

@riverpod
class OutputFileNameTpl extends _$OutputFileNameTpl {
  @override
  String build() =>
      ref.watch(metadataSettingsProvider.select((state) => state.fileNameTpl));

  void setTpl(String tpl) => state = tpl;
}

@riverpod
class ClearMetadata extends _$ClearMetadata {
  @override
  bool build() => true;

  void set(bool value) => value ? enable() : disable();

  void enable() {
    state = true;
  }

  void disable() {
    state = false;
    ref.read(rewriteMetadataProvider.notifier).disable();
  }
}

@riverpod
class RewriteMetadata extends _$RewriteMetadata {
  @override
  bool build() => true;

  void set(bool value) => value ? enable() : disable();

  void enable() {
    state = true;
    ref.read(clearMetadataProvider.notifier).enable();
  }

  void disable() {
    state = false;
  }
}
