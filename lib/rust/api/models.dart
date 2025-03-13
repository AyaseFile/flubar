// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.8.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;
part 'models.freezed.dart';

// These functions are ignored because they are not marked as `pub`: `new`, `new`
// These function are ignored because they are on traits that is not defined in current crate (put an empty `#[frb]` on it to unignore): `clone`, `fmt`, `fmt`

@freezed
class Metadata with _$Metadata {
  const factory Metadata({
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? discTotal,
    String? date,
    String? genre,
    Uint8List? frontCover,
  }) = _Metadata;
}

@freezed
class Properties with _$Properties {
  const factory Properties({
    double? durationSec,
    double? cueStartSec,
    double? cueDurationSec,
    String? codec,
    String? sampleFormat,
    int? sampleRate,
    int? bitsPerRawSample,
    int? bitsPerCodedSample,
    int? bitRate,
    int? channels,
  }) = _Properties;
}
