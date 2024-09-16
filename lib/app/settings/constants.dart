import 'package:flubar/models/state/settings.dart';

class DefaultSettings {
  static const kDarkMode = false;
  static const kFfmpegPath = '/usr/bin/ffmpeg';
  static const kFileNameTpl = '%filename%';
  static const kForceWriteMetadata = false;
  static const kTranscodeFormat = TranscodeFormat.flac;
  static const kIsolateCount = 4;
  static const kDefaultMp3Bitrate = 192;
  static const kDefaultFlacCompressionLevel = 5;
  static const kDefaultWavEncoder = FfmpegEncoder.pcm_s16le;
  static const kRememberTranscodeChoice = true;
}
