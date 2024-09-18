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
import 'package:flubar/models/state/track.dart';
import 'package:flubar/rust/api/lofty.dart';
import 'package:flubar/rust/frb_generated.dart';
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
    with IsolateMixin<(FfmpegCommand, Track, String)> {
  late FfmpegCommand _baseCommand;
  late String? _ext;
  late TemplateProcessor _tplProcessor;
  late bool _useOriginalDir;
  late String? _customOutputDir;

  @override
  void build() {
    ref.keepAlive();
  }

  void setIsolateTask({required bool rewrite}) {
    isolateTask = (List<dynamic> args) async {
      if (rewrite) await RustLib.init();
      final sendPort = args[0] as SendPort;
      final transcodeData = args[1] as List<(FfmpegCommand, Track, String)>;
      for (final (baseCommand, track, outputFile) in transcodeData) {
        final path = track.path;
        try {
          // 检查输出文件是否存在
          final file = File(outputFile);
          if (file.existsSync() &&
              !baseCommand.args.contains(const CliArg(name: 'y'))) {
            sendPort.send({
              'error': '输出文件 $outputFile 已存在',
            });
            continue;
          }
          final command = baseCommand.copyWith(
            inputs: [FfmpegInput.asset(path)],
            outputFilepath: outputFile,
          );
          final cli = command.toCli();
          final process = await Process.start(cli.executable, cli.args);
          final exitCode = await process.exitCode;
          if (exitCode == 0) {
            if (!rewrite) return;
            final metadata = track.metadata;
            await loftyWriteMetadata(
                file: outputFile,
                metadata: metadata,
                force: true); // 清除了元数据, 需要强制写入
            await loftyWritePicture(
                file: outputFile, picture: metadata.frontCover, force: true);
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
      if (rewrite) RustLib.dispose();
    };
  }

  static FfmpegCommand buildFfmpegCommand({
    required String ffmpegPath,
    required TranscodeOptions options,
    required bool overwriteExistingFiles,
    required bool clearMetadata,
  }) {
    final args = <CliArg>[];

    options.map(
      copy: (_) {
        args.add(const CliArg(name: 'c:a', value: 'copy'));
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

    if (clearMetadata) {
      args.addAll([
        const CliArg(name: 'bitexact'),
        const CliArg(name: 'map', value: '0:a'),
        const CliArg(name: 'map_metadata', value: '-1'),
      ]);
    }

    return FfmpegCommand.simple(
      ffmpegPath: ffmpegPath,
      inputs: [],
      args: args,
      outputFilepath: '',
    );
  }

  @override
  List<(FfmpegCommand, Track, String)> getData() {
    final selectedTracks = ref.read(selectedTracksProvider);
    return selectedTracks.map((track) {
      final path = track.path;
      final metadata = track.metadata;
      final dir = _useOriginalDir
          ? p.dirname(path)
          : (_customOutputDir ?? p.dirname(path));
      final newName = _tplProcessor.process(
          metadata: metadata, path: path, extension: _ext);
      final outputFile = p.join(dir, newName);
      return (_baseCommand, track, outputFile);
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
    final clearMetadata = ref.read(clearMetadataProvider);
    final rewrite = ref.read(rewriteMetadataProvider);
    setIsolateTask(rewrite: rewrite);
    _baseCommand = buildFfmpegCommand(
      ffmpegPath: ffmpegPath,
      options: options,
      overwriteExistingFiles: overwrite,
      clearMetadata: clearMetadata,
    );
    _ext = options.map(
      copy: (_) => null,
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
