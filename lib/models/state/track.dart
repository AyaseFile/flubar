import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:metadata_god/metadata_god.dart';

part 'track.freezed.dart';

@freezed
class Track with _$Track {
  const factory Track({
    required int id,
    required String path,
    required Metadata metadata,
  }) = _Track;
}
