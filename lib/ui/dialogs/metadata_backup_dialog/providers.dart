import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flubar/models/state/metadata_backup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
int matchingItem(Ref ref) => throw UnimplementedError();

@riverpod
class Path extends _$Path {
  @override
  String? build() => null;

  void set(String? path) => state = path;

  void reset() => state = null;
}

@riverpod
class MetadataBackup extends _$MetadataBackup {
  @override
  MetadataBackupModel build() =>
      const MetadataBackupModel(version: 0, metadataList: IList.empty());

  void set(MetadataBackupModel backup) => state = backup;

  void reset() => state = const MetadataBackupModel(
    version: 0,
    metadataList: IList.empty(),
  );
}
