import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class EncoderSelection extends _$EncoderSelection {
  @override
  FfmpegEncoder build() =>
      ref.watch(transcodeSettingsProvider.select((state) => state.wavEncoder));

  void select(FfmpegEncoder value) => state = value;
}

@riverpod
FfmpegEncoder encoderItem(Ref ref) => throw UnimplementedError();
