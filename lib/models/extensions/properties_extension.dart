import 'package:flubar/rust/api/models.dart';

extension PropertiesExtension on Properties {
  Map<String, dynamic> toJson() {
    return {
      'durationsec': durationSec,
      'cuestartsec': cueStartSec,
      'cuedurationsec': cueDurationSec,
      'codec': codec,
      'sampleformat': sampleFormat,
      'bitsperrawsample': bitsPerRawSample,
      'bitspercodedsample': bitsPerCodedSample,
      'bitrate': bitRate,
      'samplerate': sampleRate,
      'channels': channels,
    };
  }

  bool isCue() => durationSec == null && cueStartSec != null;

  double? get duration => isCue() ? cueDurationSec : durationSec;
}
