import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';
import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/app/talker.dart';
import 'package:flubar/models/cancel_token/cancel_token.dart';
import 'package:flubar/models/exceptions/ffmpeg_exception.dart';
import 'package:flubar/models/extensions/ffmpeg_command.dart';
import 'package:flubar/models/isolate/mixin.dart';
import 'package:flubar/ui/dialogs/metadata_dialog/providers.dart';
import 'package:flubar/ui/dialogs/transcode_dialog/providers.dart';
import 'package:flubar/utils/template/providers.dart';
import 'package:flubar/utils/template/template.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'transcode.dart';

part 'providers.g.dart';

@riverpod
class TranscodeUtil extends _$TranscodeUtil
    with IsolateMixin<(FfmpegCommand, String, String)> {
  late FfmpegCommand _baseCommand;
  late String? _ext;
  late TemplateProcessor _tplProcessor;
  late bool _useOriginalDir;
  late String? _customOutputDir;

  @override
  void build() {
    ref.keepAlive();
    isolateTask ??= (List<dynamic> args) async {
      final sendPort = args[0] as SendPort;
      final transcodeData = args[1] as List<(FfmpegCommand, String, String)>;
      for (final (baseCommand, path, outputFile) in transcodeData) {
        try {
          final command = baseCommand.copyWith(
            inputs: [FfmpegInput.asset(path)],
            outputFilepath: outputFile,
          );
          final cli = command.toCli();
          final process = await Process.start(cli.executable, cli.args);
          final exitCode = await process.exitCode;
          if (exitCode == 0) {
            sendPort.send({'error': null});
          } else {
            final stderr = await process.stderr.transform(utf8.decoder).join();
            sendPort.send({
              'error': '无法转码文件 $path. 退出码: $exitCode',
              'e': FfmpegException(stderr.trim())
            });
          }
        } catch (e, st) {
          sendPort.send({'error': '无法转码文件 $path', 'e': e, 'st': st});
        }
      }
    };
  }

  static FfmpegCommand buildFfmpegCommand(
      {required String ffmpegPath,
      required TranscodeOptions options,
      required bool overwriteExistingFiles}) {
    final args = <CliArg>[];

    options.map(
      copy: (_) {
        args.add(const CliArg(name: 'c:a', value: 'copy'));
      },
      noMetadata: (_) {
        args.addAll([
          const CliArg(name: 'c:a', value: 'copy'),
          const CliArg(name: 'bitexact'),
          const CliArg(name: 'map_metadata', value: '-1'),
        ]);
      },
      mp3: (mp3) {
        args.addAll([
          const CliArg(name: 'c:a', value: 'libmp3lame'),
          CliArg(name: 'b:a', value: '${mp3.bitrate}k'),
        ]);
      },
      flac: (flac) {
        args.addAll([
          const CliArg(name: 'c:a', value: 'flac'),
          CliArg(name: 'compression_level', value: '${flac.compressionLevel}'),
        ]);
      },
      wav: (wav) {
        args.add(CliArg(name: 'c:a', value: wav.encoder.displayName));
      },
    );

    if (overwriteExistingFiles) args.add(const CliArg(name: 'y'));

    return FfmpegCommand.simple(
      ffmpegPath: ffmpegPath,
      inputs: [],
      args: args,
      outputFilepath: '',
    );
  }

  @override
  List<(FfmpegCommand, String, String)> getData() {
    final selectedTracks = ref.read(selectedTracksProvider);
    return selectedTracks.map((track) {
      final dir = _useOriginalDir
          ? p.dirname(track.path)
          : (_customOutputDir ?? p.dirname(track.path));
      final newName = _tplProcessor.process(
          metadata: track.metadata, path: track.path, extension: _ext);
      final outputFile = p.join(dir, newName);
      return (_baseCommand, track.path, outputFile);
    }).toList();
  }

  @override
  int getIsolateCount() =>
      ref.read(settingsProvider.select((state) => state.isolateCount));

  @override
  void init() {
    final options = ref.read(transcodeOptsProvider);
    final ffmpegPath =
        ref.read(settingsProvider.select((state) => state.ffmpegPath));
    final overwrite = ref.read(overwriteExistingFilesProvider);
    _baseCommand = buildFfmpegCommand(
      ffmpegPath: ffmpegPath,
      options: options,
      overwriteExistingFiles: overwrite,
    );
    _ext = options.map(
      copy: (_) => null,
      noMetadata: (_) => null,
      mp3: (_) => '.mp3',
      flac: (_) => '.flac',
      wav: (_) => '.wav',
    );
    ref
        .read(tplUtilProvider.notifier)
        .setTpl(ref.read(outputFileNameTplProvider));
    _tplProcessor = ref.read(tplUtilProvider);
    _useOriginalDir = ref.read(useOriginalDirectoryProvider);
    _customOutputDir = ref.read(outputDirectoryProvider);
  }

  @override
  void onCancellation(CancelException e) => transcodeTalker
      .info('转码操作已取消.${e.reason != null ? ' 原因: ${e.reason}' : ''}');

  @override
  void onCompletion(Duration duration) {
    transcodeTalker.info('转码操作结束. 耗时: $duration');
    ref.read(tplUtilProvider.notifier).resetTpl();
  }

  @override
  void onError(Object e, StackTrace st) =>
      transcodeTalker.handle(e, st, '转码操作失败');

  @override
  void onIsolatesCompletion(List<Isolate> isolates) {
    for (final isolate in isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
  }

  @override
  void onProgress(double progress) =>
      ref.read(transcodeProgressProvider.notifier).setProgress(progress);

  @override
  void onTaskError(String? error, Object? e, StackTrace? st) {
    ref.read(transcodeFailedCountProvider.notifier).increment();
    transcodeTalker.error(error, e, st);
  }
}
