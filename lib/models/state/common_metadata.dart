import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_metadata.freezed.dart';

@freezed
abstract class CommonMetadataModel with _$CommonMetadataModel {
  const factory CommonMetadataModel({
    required int id,
    required String key,
    required String value,
    required bool multi,
  }) = _MetadataModel;
}
