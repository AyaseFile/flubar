import 'package:flubar/app/settings/providers.dart';
import 'package:flubar/models/state/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
class Selection extends _$Selection {
  @override
  TranscodeFormat build() =>
      ref.watch(settingsProvider.select((state) => state.transcodeFormat));

  void select(TranscodeFormat value) => state = value;
}

@riverpod
TranscodeFormat selectionItem(SelectionItemRef ref) =>
    throw UnimplementedError();
