import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'storage.freezed.dart';

@freezed
class StorageModel with _$StorageModel {
  const factory StorageModel({
    required String dataPath,
    required String settingsPath,
  }) = _StorageModel;

  factory StorageModel.fromDataPath(String dataPath) {
    return StorageModel(
      dataPath: dataPath,
      settingsPath: p.join(dataPath, 'config', 'settings.json'),
    );
  }
}
