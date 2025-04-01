import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_properties.freezed.dart';

@freezed
abstract class CommonPropertiesModel with _$CommonPropertiesModel {
  const factory CommonPropertiesModel({
    required int id,
    required String key,
    required String value,
  }) = _PropertiesModel;
}
