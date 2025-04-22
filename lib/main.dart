import 'dart:convert';
import 'dart:ui';

import 'package:flubar/app/app.dart';
import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/app/storage/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/app/window/init.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:flubar/models/state/storage.dart';
import 'package:flubar/ui/widgets/player_widget/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_size/window_size.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final box = await Hive.openBox('settings', path: dataPath);

  var windowSettings = const WindowSettingsModel();
  final str = (box.get('window') as String?) ?? '{}';
  try {
    final loadedSettings = WindowSettingsModel.fromJson(
      jsonDecode(str) as Map<String, dynamic>,
    );
    final screen = await getCurrentScreen();
    if (screen != null) {
      final width = screen.visibleFrame.width;
      final height = screen.visibleFrame.height;
      if (loadedSettings.width > 0 &&
          loadedSettings.width < width &&
          loadedSettings.height > 0 &&
          loadedSettings.height < height) {
        windowSettings = windowSettings.copyWith(
          width: loadedSettings.width,
          height: loadedSettings.height,
        );
      }
    }
  } catch (e) {
    globalTalker.handle(e, null, '无法解析窗口设置: $str');
  }
  await initWindow(windowSettings.width, windowSettings.height);

  JustAudioMediaKit.ensureInitialized(
      linux: true, windows: false, macOS: false, android: false, iOS: false);
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        settingsBoxProvider.overrideWithValue(box),
        windowSettingsLoadedProvider.overrideWithValue(windowSettings),
      ],
      child: const FlubarApp(),
    ),
  );
}

class _ErrorHandler {
  const _ErrorHandler();

  void handleError(Object e, StackTrace? st) async {
    if (st != null && st.toString().contains('MediaKitPlayer')) {
      globalTalker.handle(
          PlayerException(0721, e.toString(), 0), st, '捕获到播放器异常');
      await Player.handleError();
    } else {
      globalTalker.handle(e, st, '捕获到未处理的异常');
    }
  }
}
