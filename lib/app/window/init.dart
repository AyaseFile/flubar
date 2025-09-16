import 'dart:ui';

import 'package:window_manager/window_manager.dart';

Future<void> initWindow(double width, double height) async {
  await windowManager.ensureInitialized();

  return windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: Size(width, height),
      minimumSize: const Size(700, 500),
      center: true,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
}
