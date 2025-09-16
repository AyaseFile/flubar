part of 'cli.dart';

extension CliCmdExt on CliCommand {
  String preview() => '$executable ${args.join(' ')}';
}

extension FfmpegInputExt on FfmpegInput {
  List<String> get args => ['-i', assetPath];

  String toCli() => args.join(' ');
}

extension FfmpegCommandExt on FfmpegCommand {
  CliCommand toCli() {
    return CliCommand(
      executable: ffmpegPath,
      args: [
        ...inputs.expand((input) => input.args),
        ...args.expand((arg) => [
              "-${arg.name}",
              if (arg.value != null) arg.value!,
            ]),
        outputFilepath,
      ],
    );
  }
}
