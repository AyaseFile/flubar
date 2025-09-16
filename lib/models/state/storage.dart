import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage.freezed.dart';

@freezed
abstract class StorageModel with _$StorageModel {
  const factory StorageModel({required String dataPath}) = _StorageModel;

  factory StorageModel.fromDataPath(String dataPath) {
    return StorageModel(dataPath: dataPath);
  }
}
