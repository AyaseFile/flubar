import 'package:ffmpeg_cli/ffmpeg_cli.dart';

extension FfmpegCommandCopyWith on FfmpegCommand {
  FfmpegCommand copyWith({
    String? ffmpegPath,
    List<FfmpegInput>? inputs,
    List<CliArg>? args,
    String? outputFilepath,
  }) {
    return FfmpegCommand.simple(
      ffmpegPath: ffmpegPath ?? this.ffmpegPath,
      inputs: inputs ?? this.inputs,
      args: args ?? this.args,
      outputFilepath: outputFilepath ?? this.outputFilepath,
    );
  }
}
