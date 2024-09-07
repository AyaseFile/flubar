import 'package:talker_flutter/talker_flutter.dart';

late final Talker globalTalker;
late final Talker renameTalker;
late final Talker transcodeTalker;

void initTalker() {
  globalTalker = TalkerFlutter.init(
    logger: TalkerLogger(settings: TalkerLoggerSettings()),
    settings: TalkerSettings(enabled: true, useConsoleLogs: true),
  );
  renameTalker = TalkerFlutter.init(
    logger: TalkerLogger(settings: TalkerLoggerSettings()),
    settings: TalkerSettings(enabled: true, useConsoleLogs: true),
  );
  transcodeTalker = TalkerFlutter.init(
    logger: TalkerLogger(settings: TalkerLoggerSettings()),
    settings: TalkerSettings(enabled: true, useConsoleLogs: true),
  );
}
