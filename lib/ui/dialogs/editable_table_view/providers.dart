import 'package:flubar/models/state/track.dart';
import 'package:flubar/ui/view/tracklist_view/advanced_column.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
List<AdvancedColumn> editableTableColumns(EditableTableColumnsRef ref) =>
    throw UnimplementedError();

@riverpod
Track editableTrackItem(EditableTrackItemRef ref) => throw UnimplementedError();
