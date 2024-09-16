// ignore_for_file: constant_identifier_names
import 'package:flubar/app/settings/constants.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';

part 'settings.g.dart';

typedef _S = DefaultSettings;

enum TranscodeFormat {
  copy('Copy'),
  mp3('MP3'),
  flac('FLAC'),
  wav('WAV');

  final String displayName;

  const TranscodeFormat(this.displayName);
}

enum FfmpegEncoder {
  pcm_u8('pcm_u8'),
  pcm_s16le('pcm_s16le'),
  pcm_s16be('pcm_s16be'),
  pcm_s24le('pcm_s24le'),
  pcm_s24be('pcm_s24be'),
  pcm_s32le('pcm_s32le'),
  pcm_s32be('pcm_s32be'),
  pcm_f32le('pcm_f32le'),
  pcm_f32be('pcm_f32be');

  final String displayName;

  const FfmpegEncoder(this.displayName);
}

@freezed
class SettingsModel with _$SettingsModel {
  const factory SettingsModel({
    @Default(_S.kDarkMode) bool darkMode,
    @Default(_S.kFfmpegPath) String ffmpegPath,
    @Default(_S.kFileNameTpl) String fileNameTpl,
    @Default(_S.kForceWriteMetadata) bool forceWriteMetadata,
    @Default(_S.kTranscodeFormat) TranscodeFormat transcodeFormat,
    @Default(_S.kIsolateCount) int isolateCount,
    @Default(_S.kDefaultMp3Bitrate) int mp3Bitrate,
    @Default(_S.kDefaultFlacCompressionLevel) int flacCompressionLevel,
    @Default(_S.kDefaultWavEncoder) FfmpegEncoder wavEncoder,
    @Default(_S.kRememberTranscodeChoice) bool rememberTranscodeChoice,
  }) = _SettingsModel;

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);
}
