import 'package:flubar/models/state/settings.dart';

class DefaultSettings {
  static const kDarkMode = false;
  static const kWriteToMemoryOnly = false;
  static const kForceWriteMetadata = false;
  static const kFileNameTpl = '%filename%';
  static const kFfmpegPath = '/usr/bin/ffmpeg';
  static const kIsolateCount = 4;
  static const kTranscodeFormat = TranscodeFormat.flac;
  static const kDefaultMp3Bitrate = 192;
  static const kDefaultFlacCompressionLevel = 5;
  static const kDefaultWavEncoder = FfmpegEncoder.pcm_s16le;
  static const kRememberTranscodeChoice = true;
  static const kUseOriginalDirectory = true;
  static const kOverwriteExistingFiles = false;
  static const kClearMetadata = true;
  static const kKeepAudioOnly = true;
  static const kRewriteMetadata = true;
  static const kRewriteFrontCover = true;
  static const kWarningToLossy = false;
  static const kWarningFloatToInt = true;
  static const kWindowWidth = 800.0;
  static const kWindowHeight = 600.0;
}
