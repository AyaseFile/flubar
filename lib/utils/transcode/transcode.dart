import 'package:flubar/app/settings/constants.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transcode.freezed.dart';

typedef _S = DefaultSettings;

@freezed
class TranscodeOptions with _$TranscodeOptions {
  const factory TranscodeOptions.copy() = CopyTranscodeOptions;

  const factory TranscodeOptions.mp3({
    @Default(_S.kDefaultMp3Bitrate) int bitrate,
  }) = Mp3TranscodeOptions;

  const factory TranscodeOptions.flac({
    @Default(_S.kDefaultFlacCompressionLevel) int compressionLevel,
  }) = FlacTranscodeOptions;

  const factory TranscodeOptions.wavPack() = WavPackTranscodeOptions;

  const factory TranscodeOptions.wav({
    @Default(_S.kDefaultWavEncoder) FfmpegEncoder encoder,
  }) = WavTranscodeOptions;
}
