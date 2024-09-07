import 'package:flubar/app/talker.dart';
import 'package:metadata_god/metadata_god.dart';

class MetadataReader {
  static Future<Metadata?> read({required String file}) async {
    try {
      return await MetadataGod.loftyReadMetadata(file: file);
    } catch (loftyError) {
      try {
        return await MetadataGod.id3ReadMetadata(file: file);
      } catch (id3Error) {
        globalTalker.error('无法读取元数据: $file', [loftyError, id3Error]);
        return null;
      }
    }
  }
}
