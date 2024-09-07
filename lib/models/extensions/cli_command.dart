import 'package:ffmpeg_cli/ffmpeg_cli.dart';

extension CliCommandPreview on CliCommand {
  String preview() => '$executable ${args.join(' ')}';
}
