import 'dart:convert';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'metadata_backup.freezed.dart';

part 'metadata_backup.g.dart';

@freezed
abstract class MetadataBackupModel with _$MetadataBackupModel {
  const factory MetadataBackupModel({
    required int version,
    required IList<MetadataBackupItem> metadataList,
    @Default(IListConst([])) IList<String> frontCovers,
  }) = _MetadataBackup;

  factory MetadataBackupModel.fromJson(Map<String, dynamic> json) =>
      _$MetadataBackupFromJson(json);
}

extension MetadataBackupModelExtension on MetadataBackupModel {
  String toFormattedJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}

@freezed
abstract class MetadataBackupItem with _$MetadataBackupItem {
  const factory MetadataBackupItem({
    required String path,
    int? frontCoverIndex,
    required IMap<String, dynamic> metadata,
  }) = _MetadataBackupItem;

  factory MetadataBackupItem.fromJson(Map<String, dynamic> json) =>
      _$MetadataBackupItemFromJson(json);
}

@freezed
abstract class MatchResult with _$MatchResult {
  const factory MatchResult({
    required IMap<int, int> matches,
    required ISet<int> conflicts,
  }) = _MatchResult;
}

@freezed
abstract class MatchState with _$MatchState {
  const factory MatchState({
    required IMap<int, IList<int>> candidates,
    required MatchResult result,
  }) = _MatchState;
}
