import 'package:flubar/app/talker.dart';
import 'package:metadata_god/metadata_god.dart';

class MetadataUpdater {
  static Future<TagType> write({
    required Metadata metadata,
    required String file,
  }) async {
    final exceptions = <Object>[];
    if (metadata.tagType == TagType.id3) {
      // 对于 id3, 优先使用 id3WriteMetadata
      try {
        await MetadataGod.id3WriteMetadata(file: file, metadata: metadata);
        return TagType.id3;
      } catch (e) {
        exceptions.add(e);
        try {
          return await MetadataGod.loftyWriteMetadata(
              file: file, metadata: metadata);
        } catch (e) {
          exceptions.add(e);
          try {
            return await MetadataGod.loftyWriteMetadata(
                file: file, metadata: metadata, createTagIfMissing: true);
          } catch (e) {
            exceptions.add(e);
          }
        }
      }
    } else {
      // 对于其他类型, 优先使用 loftyWriteMetadata
      try {
        return await MetadataGod.loftyWriteMetadata(
            file: file, metadata: metadata);
      } catch (e) {
        exceptions.add(e);
        try {
          await MetadataGod.id3WriteMetadata(file: file, metadata: metadata);
          return TagType.id3;
        } catch (e) {
          exceptions.add(e);
          try {
            return await MetadataGod.loftyWriteMetadata(
                file: file, metadata: metadata, createTagIfMissing: true);
          } catch (e) {
            exceptions.add(e);
          }
        }
      }
    }
    globalTalker.error('无法更新元数据: $file', exceptions);
    return TagType.unknown;
  }
}
