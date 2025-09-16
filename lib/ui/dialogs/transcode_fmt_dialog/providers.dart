import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class Selection extends _$Selection {
  @override
  TranscodeFormat build() => ref.watch(
    transcodeSettingsProvider.select((state) => state.transcodeFormat),
  );

  void select(TranscodeFormat value) => state = value;
}

@riverpod
TranscodeFormat selectionItem(Ref ref) => throw UnimplementedError();
