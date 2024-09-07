import 'package:flubar/app/window/constants.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initWindow() async {
  await windowManager.ensureInitialized();

  windowManager.waitUntilReadyToShow(kWindowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
