import 'package:flubar/rust/api/models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'track.freezed.dart';

@freezed
class Track with _$Track {
  const factory Track({
    required int id,
    required String path,
    required Metadata metadata,
    required Properties properties,
  }) = _Track;
}
