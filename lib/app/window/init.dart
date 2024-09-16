import 'dart:ui';

import 'package:window_manager/window_manager.dart';

Future<void> initWindow(Size size) async {
  await windowManager.ensureInitialized();

  windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: const Size(700, 500),
        center: true,
      ), () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
