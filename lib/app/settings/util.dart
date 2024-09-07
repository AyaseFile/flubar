import 'dart:convert';
import 'dart:io';

import 'package:flubar/app/storage/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'util.g.dart';

@riverpod
class StorageUtil extends _$StorageUtil {
  @override
  void build() {}

  void writeSettingsSync(SettingsModel settings) {
    final settingsPath = ref.read(storageProvider).settingsPath;
    final settingsFile = File(settingsPath);
    try {
      if (!settingsFile.existsSync()) settingsFile.createSync(recursive: true);
      settingsFile.writeAsStringSync(jsonEncode(settings.toJson()));
      globalTalker.debug('写入设置: $settingsPath');
    } catch (e) {
      globalTalker.handle(e, null, '无法写入设置: $settingsPath');
    }
  }
}
