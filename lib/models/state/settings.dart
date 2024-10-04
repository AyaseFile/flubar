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
class GeneralSettingsModel with _$GeneralSettingsModel {
  const factory GeneralSettingsModel({
    @Default(_S.kDarkMode) bool darkMode,
  }) = _GeneralSettings;

  factory GeneralSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$GeneralSettingsModelFromJson(json);
}

@freezed
class MetadataSettingsModel with _$MetadataSettingsModel {
  const factory MetadataSettingsModel({
    @Default(_S.kWriteToMemoryOnly) bool writeToMemoryOnly,
    @Default(_S.kForceWriteMetadata) bool forceWriteMetadata,
    @Default(_S.kFileNameTpl) String fileNameTpl,
  }) = _MetadataSettings;

  factory MetadataSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$MetadataSettingsModelFromJson(json);
}

@freezed
class TranscodeSettingsModel with _$TranscodeSettingsModel {
  const factory TranscodeSettingsModel({
    @Default(_S.kFfmpegPath) String ffmpegPath,
    @Default(_S.kIsolateCount) int isolateCount,
    @Default(_S.kTranscodeFormat) TranscodeFormat transcodeFormat,
    @Default(_S.kDefaultMp3Bitrate) int mp3Bitrate,
    @Default(_S.kDefaultFlacCompressionLevel) int flacCompressionLevel,
    @Default(_S.kDefaultWavEncoder) FfmpegEncoder wavEncoder,
    @Default(_S.kRememberTranscodeChoice) bool rememberTranscodeChoice,
    @Default(_S.kUseOriginalDirectory) bool useOriginalDirectory,
    @Default(_S.kOverwriteExistingFiles) bool overwriteExistingFiles,
    @Default(_S.deleteOriginalFiles) bool deleteOriginalFiles,
    @Default(_S.kClearMetadata) bool clearMetadata,
    @Default(_S.kKeepAudioOnly) bool keepAudioOnly,
    @Default(_S.kRewriteMetadata) bool rewriteMetadata,
    @Default(_S.kRewriteFrontCover) bool rewriteFrontCover,
  }) = _TranscodeSettings;

  factory TranscodeSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$TranscodeSettingsModelFromJson(json);
}

@freezed
class TranscodeWarningsModel with _$TranscodeWarningsModel {
  const factory TranscodeWarningsModel({
    @Default(_S.kWarningToLossy) bool toLossy,
    @Default(_S.kWarningFloatToInt) bool floatToInt,
    @Default(_S.kWarningHighToLowBit) bool highToLowBit,
  }) = _TranscodeWarnings;

  factory TranscodeWarningsModel.fromJson(Map<String, dynamic> json) =>
      _$TranscodeWarningsModelFromJson(json);
}

@freezed
class WindowSettingsModel with _$WindowSettingsModel {
  const factory WindowSettingsModel({
    @Default(_S.kWindowWidth) double width,
    @Default(_S.kWindowHeight) double height,
  }) = _WindowSettings;

  factory WindowSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$WindowSettingsModelFromJson(json);
}
