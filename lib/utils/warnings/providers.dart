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
    return switch (opts) {
      CopyTranscodeOptions() => 0,
      Mp3TranscodeOptions() => 0,
      FlacTranscodeOptions() => 24,
      WavPackTranscodeOptions() => 0,
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_u8) => 8,
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_s16le) ||
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_s16be) =>
        16,
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_s24le) ||
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_s24be) =>
        24,
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_s32le) ||
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_s32be) ||
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_f32le) ||
      WavTranscodeOptions(encoder: FfmpegEncoder.pcm_f32be) =>
        32,
    };
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
    return switch (opts) {
      CopyTranscodeOptions() => false,
      Mp3TranscodeOptions() => true,
      FlacTranscodeOptions() => false,
      WavPackTranscodeOptions() => false,
      WavTranscodeOptions() => false,
    };
  }

  bool _isFloat(String? sampleFormat) =>
      sampleFormat == null ? false : sampleFormat.startsWith('f');

  bool _isIntTranscode(TranscodeOptions opts) {
    return switch (opts) {
      CopyTranscodeOptions() => false,
      Mp3TranscodeOptions() => false,
      FlacTranscodeOptions() => true,
      WavPackTranscodeOptions() => false,
      WavTranscodeOptions(:final encoder) => switch (encoder) {
          FfmpegEncoder.pcm_f32le || FfmpegEncoder.pcm_f32be => false,
          _ => true,
        },
    };
  }
}
