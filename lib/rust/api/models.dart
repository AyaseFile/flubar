// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.7.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// These functions are ignored because they are not marked as `pub`: `new`, `new`
// These function are ignored because they are on traits that is not defined in current crate (put an empty `#[frb]` on it to unignore): `clone`, `fmt`, `fmt`

class Metadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final String? date;
  final String? genre;
  final Uint8List? frontCover;

  const Metadata({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.date,
    this.genre,
    this.frontCover,
  });

  @override
  int get hashCode =>
      title.hashCode ^
      artist.hashCode ^
      album.hashCode ^
      albumArtist.hashCode ^
      trackNumber.hashCode ^
      trackTotal.hashCode ^
      discNumber.hashCode ^
      discTotal.hashCode ^
      date.hashCode ^
      genre.hashCode ^
      frontCover.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Metadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist &&
          album == other.album &&
          albumArtist == other.albumArtist &&
          trackNumber == other.trackNumber &&
          trackTotal == other.trackTotal &&
          discNumber == other.discNumber &&
          discTotal == other.discTotal &&
          date == other.date &&
          genre == other.genre &&
          frontCover == other.frontCover;
}

class Properties {
  final double? durationSec;
  final double? cueStartSec;
  final double? cueDurationSec;
  final String? codec;
  final String? sampleFormat;
  final int? sampleRate;
  final int? bitsPerRawSample;
  final int? bitsPerCodedSample;
  final int? bitRate;
  final int? channels;

  const Properties({
    this.durationSec,
    this.cueStartSec,
    this.cueDurationSec,
    this.codec,
    this.sampleFormat,
    this.sampleRate,
    this.bitsPerRawSample,
    this.bitsPerCodedSample,
    this.bitRate,
    this.channels,
  });

  @override
  int get hashCode =>
      durationSec.hashCode ^
      cueStartSec.hashCode ^
      cueDurationSec.hashCode ^
      codec.hashCode ^
      sampleFormat.hashCode ^
      sampleRate.hashCode ^
      bitsPerRawSample.hashCode ^
      bitsPerCodedSample.hashCode ^
      bitRate.hashCode ^
      channels.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Properties &&
          runtimeType == other.runtimeType &&
          durationSec == other.durationSec &&
          cueStartSec == other.cueStartSec &&
          cueDurationSec == other.cueDurationSec &&
          codec == other.codec &&
          sampleFormat == other.sampleFormat &&
          sampleRate == other.sampleRate &&
          bitsPerRawSample == other.bitsPerRawSample &&
          bitsPerCodedSample == other.bitsPerCodedSample &&
          bitRate == other.bitRate &&
          channels == other.channels;
}
