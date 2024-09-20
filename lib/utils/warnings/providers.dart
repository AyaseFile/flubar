import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/dialogs/transcode_dialog/providers.dart';
import 'package:flubar/utils/transcode/transcode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class TranscodeWarningUtil extends _$TranscodeWarningUtil {
  @override
  String build() {
    String warning = '';
    final tracks = ref.watch(selectedTracksProvider);
    final opts = ref.watch(transcodeOptsProvider);
    final warnings = ref.watch(transcodeWarningsProvider);

    if (warnings.toLossy && _isLossy(opts)) {
      warning += '使用有损转码\n';
    }
    if (warnings.floatToInt) {
      final hasFloat =
          tracks.any((track) => _isFloat(track.properties.sampleFormat));
      if (hasFloat && _isIntTranscode(opts)) {
        warning += '浮点数转整数\n';
      }
    }
    return warning.trim();
  }

  bool _isLossy(TranscodeOptions opts) {
    return opts.map(
      copy: (_) => false,
      mp3: (_) => true,
      flac: (_) => false,
      wav: (_) => false,
    );
  }

  bool _isFloat(String? sampleFormat) =>
      sampleFormat == null ? false : sampleFormat.startsWith('f');

  bool _isIntTranscode(TranscodeOptions opts) {
    return opts.map(
      copy: (_) => false,
      mp3: (_) => false,
      flac: (_) => true,
      wav: (wav) =>
          wav.encoder == FfmpegEncoder.pcm_u8 ||
          wav.encoder == FfmpegEncoder.pcm_s16le ||
          wav.encoder == FfmpegEncoder.pcm_s16be ||
          wav.encoder == FfmpegEncoder.pcm_s24le ||
          wav.encoder == FfmpegEncoder.pcm_s24be ||
          wav.encoder == FfmpegEncoder.pcm_s32le ||
          wav.encoder == FfmpegEncoder.pcm_s32be,
    );
  }
}
