import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flubar/rust/api/models.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/dialogs/transcode_dialog/providers.dart';
import 'package:flubar/utils/transcode/transcode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class TranscodeWarningUtil extends _$TranscodeWarningUtil {
  int _bitDepth = 0;

  @override
  String build() {
    String warning = '';
    final tracks = ref.watch(selectedTracksProvider);
    final opts = ref.watch(transcodeOptsProvider);
    final warnings = ref.watch(transcodeWarningsProvider);

    if (warnings.toLossy && _isLossyTranscode(opts)) {
      warning += '使用有损转码\n';
    }
    if (warnings.floatToInt) {
      final hasFloat =
          tracks.any((track) => _isFloat(track.properties.sampleFormat));
      if (hasFloat && _isIntTranscode(opts)) {
        warning += '浮点数转整数\n';
      }
    }
    if (warnings.highToLowBit) {
      _bitDepth = _getTranscodeBitDepth(opts);
      if (_bitDepth != 0) {
        final hasHighToLowBit =
            tracks.any((track) => _isHighToLowBit(track.properties));
        if (hasHighToLowBit) {
          warning += '高位转低位\n';
        }
      }
    }
    return warning.trim();
  }

  int _getTranscodeBitDepth(TranscodeOptions opts) {
    return opts.map(
      copy: (_) => 0,
      mp3: (_) => 0,
      flac: (flac) => 24,
      wav: (wav) => switch (wav.encoder) {
        FfmpegEncoder.pcm_u8 => 8,
        FfmpegEncoder.pcm_s16le || FfmpegEncoder.pcm_s16be => 16,
        FfmpegEncoder.pcm_s24le || FfmpegEncoder.pcm_s24be => 24,
        FfmpegEncoder.pcm_s32le ||
        FfmpegEncoder.pcm_s32be ||
        FfmpegEncoder.pcm_f32le ||
        FfmpegEncoder.pcm_f32be =>
          32,
      },
    );
  }

  bool _isHighToLowBit(Properties properties) {
    if (properties.codec == null) return false;
    switch (properties.codec!) {
      case 'pcm_u8':
        return 8 > _bitDepth;
      case 'pcm_s16le':
      case 'pcm_s16be':
        return 16 > _bitDepth;
      case 'pcm_s24le':
      case 'pcm_s24be':
        return 24 > _bitDepth;
      case 'pcm_s32le':
      case 'pcm_s32be':
      case 'pcm_f32le':
      case 'pcm_f32be':
        return 32 > _bitDepth;
      case 'flac':
        final trackBitDepth =
            properties.bitsPerRawSample ?? properties.bitsPerCodedSample;
        return trackBitDepth != null && trackBitDepth > _bitDepth;
      default:
        return false;
    }
  }

  bool _isLossyTranscode(TranscodeOptions opts) {
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
