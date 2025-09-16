import 'package:freezed_annotation/freezed_annotation.dart';

part 'cli.freezed.dart';

part 'ext.dart';

@freezed
abstract class CliArg with _$CliArg {
  const factory CliArg({
    required String name,
    String? value,
  }) = _CliArg;
}

@freezed
abstract class CliCommand with _$CliCommand {
  const factory CliCommand({
    required String executable,
    required List<String> args,
  }) = _CliCommand;
}

@freezed
abstract class FfmpegInput with _$FfmpegInput {
  const factory FfmpegInput.asset(String assetPath) = _FfmpegInput;
}

@freezed
abstract class FfmpegCommand with _$FfmpegCommand {
  const factory FfmpegCommand.simple({
    required String ffmpegPath,
    required List<FfmpegInput> inputs,
    required List<CliArg> args,
    required String outputFilepath,
  }) = _FfmpegCommand;
}
