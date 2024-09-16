import 'dart:io';
import 'dart:ui';

import 'package:flubar/app/app.dart';
import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/app/storage/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/app/window/init.dart';
import 'package:flubar/models/state/storage.dart';
import 'package:flubar/ui/widgets/player_widget/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initWindow();

  initTalker();
  const errorHandler = _ErrorHandler();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    errorHandler.handleError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (e, st) {
    errorHandler.handleError(e, st);
    return true;
  };

  final dataPath = (await getApplicationSupportDirectory()).path;
  final storage = StorageModel.fromDataPath(dataPath);
  final settingsString = () {
    try {
      return File(storage.settingsPath).readAsStringSync();
    } catch (e) {
      globalTalker.handle(e, null, '无法读取设置文件: ${storage.settingsPath}');
      return '{}';
    }
  }();

  JustAudioMediaKit.ensureInitialized(
      linux: true, windows: false, macOS: false, android: false, iOS: false);
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        settingsStringProvider.overrideWithValue(settingsString),
      ],
      child: const FlubarApp(),
    ),
  );
}

class _ErrorHandler {
  const _ErrorHandler();

  void handleError(Object e, StackTrace? st) async {
    if (st != null && st.toString().contains('MediaKitPlayer')) {
      globalTalker.handle(PlayerException(0721, e.toString()), st, '捕获到播放器异常');
      await Player.handleError();
    } else {
      globalTalker.handle(e, st, '捕获到未处理的异常');
    }
  }
}
