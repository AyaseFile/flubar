import 'package:flubar/rust/api/models.dart';

extension PropertiesExtension on Properties {
  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'codec': codec,
      'sampleformat': sampleFormat,
      'bitsperrawsample': bitsPerRawSample,
      'bitspercodedsample': bitsPerCodedSample,
      'bitrate': bitRate,
      'samplerate': sampleRate,
      'channels': channels,
    };
  }
}
