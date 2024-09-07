import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'track.dart';

part 'track_cover.freezed.dart';

@freezed
class TrackCoverModel with _$TrackCoverModel {
  const factory TrackCoverModel({
    @Default(false) bool updated,
    @Default(null) Uint8List? oldCover,
    @Default(null) Uint8List? newCover,
    @Default('') String mimeType,
    required List<Track> tracks,
  }) = _TrackCover;
}

extension RemoveCover on TrackCoverModel {
  TrackCoverModel removeCover() {
    return TrackCoverModel(
      updated: true,
      oldCover: oldCover,
      newCover: null,
      mimeType: mimeType,
      tracks: tracks,
    );
  }
}
